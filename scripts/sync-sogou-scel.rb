#!/usr/bin/env ruby

require "pry"
require "open-uri"
require 'mechanize'
require "pathname"
require "terrapin"
require "date"


CELLS = {
  "popular" => [
    4, # 网络流行新词
  ],
  "games" => [
    78464, # Fate/Grand Order
    12398, # 魔兽世界官方版
  ]
}

BASE = Pathname.new(__dir__)
BUILD = BASE.parent.join("data", "sogou", "raw")
OUTPUT = BASE.parent.join("data", "sogou")
BUILD.mkpath

# SCEL parser adapted from xwzhong, with the Python port by PeterCxy.
class ScelReader
  def initialize(path)
    @data = path.binread
    @offset = 0
  end

  def read(length)
    if @offset + length > @data.bytesize
      raise ArgumentError, "SCEL 数据不完整，偏移：#{@offset}"
    end

    bytes = @data.byteslice(@offset, length)
    @offset += length
    bytes
  end

  def read_uint16
    read(2).unpack1("v")
  end

  def read_string
    length = read_uint16
    raise ArgumentError, "无效的 UTF-16 字符串长度" if length.odd?

    read(length).force_encoding("UTF-16LE").encode("UTF-8").delete(" ").tr("\r", "\n")
  end

  def to_txt
    word_offset = case read(12)
    when "\x40\x15\x00\x00DCS\x01\x01\x00\x00\x00".b
      0x2628
    when "\x40\x15\x00\x00ECS\x01\x01\x00\x00\x00".b
      0x26c4
    else
      raise ArgumentError, "不支持的搜狗(.scel)词库格式"
    end

    @offset = 0x124
    word_count = read(4).unpack1("V")
    @offset = 0x1540
    pinyin_count = read(4).unpack1("V")
    pinyin_table = {}
    pinyin_count.times do
      index = read_uint16
      pinyin_table[index] = read_string
    end

    @offset = word_offset
    output = +""
    converted = 0
    # ECS 词条后还有附加数据，按文件头的词条总数停止读取。
    while converted < word_count
      same = read_uint16
      if same.zero? || converted + same > word_count
        raise ArgumentError, "词条数量与文件头不一致"
      end

      pinyin_length = read_uint16
      raise ArgumentError, "无效的拼音索引表长度" if pinyin_length.odd?

      pinyin = read(pinyin_length).unpack("v*").map { |index| pinyin_table.fetch(index) }.join(" ").strip
      same.times do
        word = read_string
        extension_length = read_uint16
        raise ArgumentError, "无效的词条扩展信息长度" if extension_length < 2

        weight = read(extension_length).unpack1("v")
        output << "#{word}\t#{pinyin}\t#{weight}\n"
      end
      converted += same
    end
    output
  end
end

def clean
  BUILD.rmtree()
end

def download(code, id)
  agent = Mechanize.new
  page = agent.get("https://pinyin.sogou.com/dict/detail/index/#{id}")
  file = BUILD.join("#{code}.#{id}.scel")
  page.link_with(id: "dict_#{id}").click.save!(file)
  puts "done"
end

def download_all
  BUILD.mkpath()

  CELLS.each do |code, ids|
    print "Start download #{code} ... "
    ids.each do |id|
      download(code, id)
    end
  end
end


def convert(code, ids)
  OUTPUT.mkpath
  print "Convert scel to txt ... "
  text_files = ids.map do |id|
    scel_file = BUILD.join("#{code}.#{id}.scel")
    text_file = scel_file.sub_ext(".txt")
    text_file.write(ScelReader.new(scel_file).to_txt)
    text_file
  end
  text_files.each do |path|
    raise "SCEL conversion did not produce a non-empty TXT file: #{path}" unless path.file? && path.size > 0
  end
  puts "done"

  print "Convert to simplified and combine txt to dict ... "

  line = Terrapin::CommandLine.new("opencc", "-c t2s.json -i :input")
  entries = {}
  text_files.each do |path|
    line.run(input: path).each_line do |entry|
      word, pinyin, weight = entry.chomp.split("\t")
      key = [word, pinyin]
      entries[key] = [entries.fetch(key, 0), Integer(weight)].max
    end
  end

  File.open(OUTPUT.join("sogou.#{code}.dict.yaml"), "wb") do |file|
    file << <<~HEREDOC
      ---
      name: sogou.#{code}
      version: "#{Date.today}"
      sort: by_weight
      use_preset_vocabulary: true
      ...

    HEREDOC

    entries.each do |(word, pinyin), weight|
      file << "#{word}\t#{pinyin}\t#{weight}\n"
    end
  end
  puts "done"
end

def convert_all
  CELLS.each do |code, ids|
    print "Start convert #{code} ... "
    convert(code, ids)
  end
end


case ARGV[0]
when "download"
  download_all
when "convert"
  convert_all
when "clean"
  clean
else
  clean
  download_all
  convert_all
end

#!/usr/bin/env ruby

require "pry"
require "open-uri"
require 'mechanize'
require "pathname"
require "terrapin"


CELLS = {
  "popular" => [
    4, # 网络流行新词
  ],
  "games" => [
    78464, # Fate/Grand Order
    15233, # 魔兽世界【官方推荐】
  ]
}

BASE = Pathname.new(__dir__)
BUILD = BASE.join("build", "sogou")
BUILD.mkpath

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
  print "Convert scel to txt ... "
  scel_files = ids.map { |id| BUILD.join("#{code}.#{id}.scel") }
  line = Terrapin::CommandLine.new("python3", ":script :files")
  line.run(script: BASE.join("scel-rime/scel2txt.py"), files: scel_files)
  puts "done"

  print "Combine txt to dict ... "
  text_files = scel_files = ids.map { |id| BUILD.join("#{code}.#{id}.txt") }

  orig_dict = BUILD.join("extended.sogou.#{code}.dict.orig.yaml")
  File.open(orig_dict, "wb") do |file|
    file << <<~HEREDOC
      ---
      name: extended.sogou
      version: "#{Date.today}"
      sort: by_weight
      use_preset_vocabulary: true
      ...

    HEREDOC

    text_files.each do |path|
      file << path.read
    end
  end
  puts "done"

  print "Convert simplified to traditional ... "
  line = Terrapin::CommandLine.new("opencc", "-i :input -o :output")
  line.run(input: orig_dict, output: Pathname.new("extended.sogou.#{code}.dict.yaml"))
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

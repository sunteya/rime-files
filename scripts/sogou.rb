#!/usr/bin/env ruby

require "pry"
require "open-uri"
require 'mechanize'
require "pathname"
require "terrapin"


ids = {
  4     => "网络流行新词",
  87320 => "Fate/Grand Order",
}

base = Pathname.new(__dir__)
build = base.join("build", "sogou")
build.rmtree()
build.mkpath()

agent = Mechanize.new
ids.each_pair do |id, name|
  print "Start download #{name} ... "
  page = agent.get("https://pinyin.sogou.com/dict/detail/index/#{id}")
  page.link_with(id: "dict_#{id}").click.save!(build.join("#{id}.scel"))
  puts "done"
end

print "Convert scel to txt ... "
scel_files = Pathname.glob(build.join("*.scel"))
line = Terrapin::CommandLine.new("python3", ":script :files")
line.run(script: base.join("scel-rime/scel2txt.py"), files: scel_files)
puts "done"

print "Combine txt to dict ... "
text_files = Pathname.glob(build.join("*.txt"))

simp_dict = build.join("extended.sogou.dict.yaml.orig")
File.open(simp_dict, "wb") do |file|
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
line.run(input: simp_dict, output: Pathname.new("extended.sogou.dict.yaml"))
puts "done"

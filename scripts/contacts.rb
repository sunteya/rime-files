#!/usr/bin/env ruby
require "pry"
require "pathname"
require "active_support/all"

base = Pathname.new(__dir__)
print "Export contacts by applescript ... "
result = %x[#{base.join("contacts-export.applescript")} 2>&1]

names = result.lines.lazy.map(&:chomp).find_all(&:present?).find_all do |name|
  skip = false
  skip ||= name.length == 1
  skip ||= name.ascii_only?
  skip ||= name.end_with?(")")
  !skip
end.uniq.to_a

File.open("extended.contacts.dict.yaml", "wb") do |file|
  file << <<~HEREDOC
    ---
    name: extended.contacts
    version: "#{Date.today}"
    sort: by_weight
    use_preset_vocabulary: true
    ...

  HEREDOC

  names.each { |name| file.puts name }
end
puts "done"

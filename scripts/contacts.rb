#!/usr/bin/env ruby
require "pry"
require "pathname"
require "active_support/all"

base = Pathname.new(__dir__)
print "Export contacts by applescript ... "
result = %x[#{base.join("contacts-export.applescript")} 2>&1]


rows = result.lines.lazy.map(&:chomp).find_all(&:present?).map do |line|
  (name, phonetic) = line.split("||")
  if phonetic
    phonetic = phonetic.unicode_normalize(:nfkd).encode("US-ASCII", replace: "")
    phonetic = phonetic.chars.slice_before { |c| c == c.upcase }.map do |phone|
      phone.join.strip
    end.join(" ").downcase.strip
  end
  [ name.strip, phonetic.presence ]
end.find_all do |(name, phonetic)|
  skip = false
  skip ||= name.length == 1
  skip ||= name.ascii_only?
  skip ||= name.end_with?(")")
  !skip
end.uniq(&:first).to_a

File.open("extended.contacts.dict.yaml", "wb") do |file|
  file << <<~HEREDOC
    ---
    name: extended.contacts
    version: "#{Date.today}"
    sort: by_weight
    use_preset_vocabulary: true
    ...

  HEREDOC

  rows.each do |(name, phonetic)|
    line = "#{name}"
    line += "\t#{phonetic}" if phonetic
    file.puts line
  end
end
puts "done"

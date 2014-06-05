#!/usr/bin/ruby

# Generate a simgle vote-api compatible JSON motions file from
# individual ones (with duplicate motions removed)
#
# Usage: bin/generate_motion_file.rb data/motions/*.json > motions-all.json

require 'json'

motions = {}

ARGV.each do |filename|
  JSON.parse(File.read(filename)).each do |motion|
    motions[motion['id']] = motion
  end
end

puts JSON.pretty_generate(motions.values)

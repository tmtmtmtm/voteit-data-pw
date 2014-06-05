#!/usr/bin/ruby

# Make a simple parties.json from the parsed issues
#
# Usage: bin/parties_from_issues.rb issues/*.json > parties.json

require 'json'
require 'set'

parties = Set.new

ARGV.each do |filename|
  warn "Reading #{filename}"
  json = JSON.parse(File.read(filename));
  json['aspects'].each do |aspect|
    aspect['motion']['vote_events'].each do |ve|
      ve['votes'].each do |vote|
        parties << vote['voter']['party'].gsub(/ \([^\)]+\)/,'').gsub(/^whilst /,'').gsub(/^Ind .*/, 'Ind')
      end
    end
  end
end

def name_of (party)
  parties = {
    "Con" => "Conservative Party",
    "Ind" => "Independent",
    "LDem" => "Liberal Democrats",
    "Lab" => "Labour Party",
    "PC" => "Plaid Cymru",
    "Res" => "Respect Party",
    "SF" => "Sinn Féin",
  }
  return parties[party] || party
end

puts JSON.pretty_generate(
  parties.reject { |p| p.match /Speaker/ }.sort.map { |party|
    {
      classification: 'party',
      id: party.downcase,
      name: name_of(party),
    }
  }
)




#!/usr/bin/ruby

# Make a vote-api compatible JSON motions file from an Issues file
#
# bin/motions_from_issues.rb issues/*.json > motions.json
# Requires a people.json in the same directory

require 'json'
require 'set'

def names_of (mp)
  [ mp['name'], (mp['other_names'] || []).map { |on| on['name'] } ].flatten
end

@mp_lookup = {}
JSON.parse(File.read('people.json')).each { |mp|
  @mp_lookup[ mp['name'] ] = mp['id']
  (mp['other_names'] || []).each { |on|
    @mp_lookup[ on['name'] ] = mp['id']
  }
} 

def motion_from (motion)
  motion['vote_events'].each do |ve|
    ve['votes'].each do |v|
      # TODO stop copying this code
      v['party_id'] = v['voter'].delete('party').gsub(/ \([^\)]+\)/,'').gsub(/^whilst /,'').gsub(/^Ind .*/, 'Ind')
      v['voter']['name'] = "Gareth R. Thomas" if v['voter']['name'] == 'Gareth Thomas' and v['voter']['constituency'] == 'Harrow West'
      v['voter']['name'] = "Angela C. Smith" if v['voter']['name'] == 'Angela Smith' and v['voter']['constituency'] != 'Basildon'
      
      v['voter'].delete('url')
      v['voter']['id'] = @mp_lookup[ v['voter']['name'] ] or raise "no such MP: #{v['voter']['name']}"
    end
  end
  motion
end



motions = ARGV.map { |filename|
  warn "Reading #{filename}"
  json = JSON.parse(File.read(filename));
  json['aspects'].map { |aspect| motion_from( aspect['motion'] ) }
}.flatten

puts JSON.pretty_generate(motions)

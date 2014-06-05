#!/usr/bin/ruby

# Make a simple people.json from the parsed issues
#
# Usage: bin/people_from_issues.rb issues/*.json > people.json

require 'json'
require 'set'
require 'i18n'

people = {}
@bounds = {
  min: '2100-01-01',
  max: '1900-01-01',
}

ARGV.each do |filename|
  warn "Reading #{filename}"
  json = JSON.parse(File.read(filename));
  json['aspects'].each do |aspect|
    aspect['motion']['vote_events'].each do |ve|
      @bounds[:min] = aspect['motion']['date'] if aspect['motion']['date'] < @bounds[:min]
      @bounds[:max] = aspect['motion']['date'] if aspect['motion']['date'] > @bounds[:max]
      ve['votes'].each do |vote|
        # Resolve later multiple people with same name
        voter = vote['voter']
        partyid  = voter['party'].gsub(/ \([^\)]+\)/,'').gsub(/^whilst /,'').gsub(/^Ind .*/, 'Ind').downcase
        name = voter['name'].sub(/^Earl of /,'')
        # TODO store each version in other_names
        %w(Reverend Professor Viscount Sir Dr Miss Mrs Mr Ms).each do |prefix| 
          name.sub!(/^#{prefix} /,'')
        end

        ((people[name] ||= {})[partyid] ||= []) << aspect['motion']['date']
      end
    end
  end
end

def id_from_name(name)
  I18n.transliterate(name).gsub(/[ \-]/,'_').gsub("'",'').downcase
end

def memberships_from(history)
  history.map { |partyid, dates|
    m = {
      organization_id: partyid,
      role: "MP",
      # area: { name: constituency }
    }
    span = dates.sort
    m[:start_date] = span.first if span.first > @bounds[:min]
    m[:end_date]   = span.last  if span.last  < @bounds[:max]
    m
  }
end

data = people.sort_by { |k,v| k }.map do |name, history|
  {
    id: id_from_name(name),
    name: name,
    memberships: memberships_from(history),
  }
end

puts JSON.pretty_generate(data)

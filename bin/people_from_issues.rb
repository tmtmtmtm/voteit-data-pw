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

@names = {}
def std_name (orig)
  if @names[orig].nil?
    std = orig.sub(/^Earl of /,'').sub(/^Lady Lady /,'Lady ')
    %w(Hon. Reverend Professor Viscount Sir Dr Miss Mrs Mr Ms).each do |prefix| 
      std.sub!(/^#{prefix} /,'')
    end
    @names[orig] = std
  end
  return @names[orig] 
end


ARGV.each do |filename|
  warn "Reading #{filename}"
  json = JSON.parse(File.read(filename));
  json['aspects'].each do |aspect|
    aspect['motion']['vote_events'].each do |ve|
      @bounds[:min] = aspect['motion']['date'] if aspect['motion']['date'] < @bounds[:min]
      @bounds[:max] = aspect['motion']['date'] if aspect['motion']['date'] > @bounds[:max]
      ve['votes'].each do |vote|
        voter = vote['voter']
        partyid  = voter['party'].gsub(/ \([^\)]+\)/,'').gsub(/^whilst /,'').gsub(/^Ind .*/, 'Ind').downcase
        name = std_name(voter['name'])
        # Hack for people with same name
        name = "Gareth R. Thomas" if name == 'Gareth Thomas' and voter['constituency'] == 'Harrow West'
        name = "Angela C. Smith" if name == 'Angela Smith' and voter['constituency'] != 'Basildon'
        ((people[name] ||= {})[partyid] ||= []) << aspect['motion']['date']
      end
    end
  end
end

def id_from_name(name)
  I18n.transliterate(name).gsub(/[ \-]/,'_').gsub(/['.]/,'').downcase
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

def names_of (name)
  data = { 
    name: name,
    other_names: '',
  }
end

data = people.sort_by { |k,v| k }.map do |name, history|
  {
    id: id_from_name(name),
    name: name,
    other_names: @names.select { |k, v| v == name and k != name }.keys.map { |n| { name: n }  },
    memberships: memberships_from(history),
  }.reject { |k, v| v.empty? }
end

puts JSON.pretty_generate(data)


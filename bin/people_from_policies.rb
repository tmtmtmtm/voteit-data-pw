#!/usr/bin/ruby

# Make a simple people.json from the parsed policies
#
# Usage: bin/people_from_policies.rb data/policies/*.json > people.json

# If a constituencies.csv file exists, mapping constituencies to which 
# area they're in, include that info too. This can be downloaded from
# https://morph.io/tmtmtmtm/uk_parliamentary_constituencies

require 'json'
require 'set'
require 'i18n'
require 'csv'

class MP
  attr_accessor :id, :name, :other_names

  @@mps = {}
  def self.find (record)
    std = standardised_name(record['name'])
    # Hack for people with same name
    std = "Gareth R. Thomas" if std == 'Gareth Thomas' and record['constituency'] == 'Harrow West'
    std = "Angela C. Smith"  if std == 'Angela Smith'  and record['constituency'] != 'Basildon'
    std = "Dr Alan Williams" if std == 'Alan Williams' and record['constituency'][/Carmarthen/]

    id = self.id_from_name(std)
    @@mps[id] ||= MP.new(id, std)
    @@mps[id].add_name(record['name'])
    @@mps[id]
  end


  def initialize (id, name)
    @id = id
    @name = name
    @other_names = Set.new
  end

  def add_name(name)
    return if name == @name 
    @other_names << name
  end

  private

  def self.standardised_name (name)
    std = name.sub(/^Earl of /,'').sub(/^Lady Lady /,'Lady ')
    %w(Hon. Reverend Professor Viscount Sir Dr Miss Mrs Mr Ms).each do |prefix| 
      std.sub!(/^#{prefix} /,'')
    end
    return std
  end

  def self.id_from_name(name)
    I18n.transliterate(name).gsub(/[ \-]/,'_').gsub(/['.]/,'').downcase
  end

end


def memberships_from(history)
  history.group_by { |hi| [hi[:partyid], hi[:constituency]] }.map { |pc, his|
    m = {
      organization_id: pc.first,
      role: "MP",
      area: { name: pc.last }
    }
    span = his.map { |h| h[:date] }.sort
    m[:start_date] = span.first if span.first > @bounds[:min]
    m[:end_date]   = span.last  if span.last  < @bounds[:max]
    m
  }
end

people = []
ARGV.each do |filename|
  warn "Reading #{filename}"
  json = JSON.parse(File.read(filename));
  json['aspects'].each do |aspect|
    aspect['motion']['vote_events'].each do |ve|
      ve['votes'].each do |vote|
        voter = vote['voter']
        partyid  = voter['party'].gsub(/ \([^\)]+\)/,'').gsub(/^whilst /,'').gsub(/^Ind .*/, 'Ind').downcase

        mp = MP.find(voter)
        people << {
          mp: mp,
          partyid: partyid,
          constituency: voter['constituency'],
          date: aspect['motion']['date'],
        }
      end
    end
  end
end

@bounds = {
  min: people.map { |p| p[:date] }.min,
  max: people.map { |p| p[:date] }.max,
}

data = people.group_by { |p| p[:mp] }.sort_by { |k,vs| k.name }.map do |mp, history|
  {
    id: mp.id,
    name: mp.name,
    other_names: mp.other_names.map { |n| { name: n } },
    memberships: memberships_from(history),
  }.reject { |k, v| v.empty? }
end

puts JSON.pretty_generate(data)


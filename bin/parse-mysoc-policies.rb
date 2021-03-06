#!/usr/bin/ruby

require 'open-uri/cached'

# Parse https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php
# into lines suitable for passing to make_issue

# This is largely replaced now by https://api.morph.io/tmtmtmtm/theyworkforyou_policies

def issue_from (line)
  return unless m = line.match( /(\d+) => '(.*)',?\s?$/ )
  return {
    id: m[1],
    text: m[2].gsub("\\'", "&rsquo;"),
  }
end

def find_policy_list (page_text)
  return page_text[/protected \$policies = array\((.*?)\);$/m, 1].split(/\n/).map { |line|
    issue_from(line)
  }.reject { |p| p.nil? }
end

def find_categories (page_text)
  lines = page_text.split(/\n/).select { |line|
    line if line =~ /private \$sets = array/ .. line =~ /\);/
  }
  lines.drop(1)
end

url = 'https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php'
page_text = open(url).read

cats = {}
section = 'XXX'
find_categories(page_text).each do |line|
  if line =~ /'([^']+)' => array/
    section = $1
  else
    id = line[/(\d+)/, 1]
    next if id.nil?
    (cats[section] ||= []) << id
  end
end


find_policy_list(page_text).each do |i|
  puts "bin/scrape_policy_json.rb #{i[:id]} #{cats.select { |k,v| v.include? i[:id] }.keys.join ","} '#{i[:text]}' > data/policies/#{i[:id]}.json"
end



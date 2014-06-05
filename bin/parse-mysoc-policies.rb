#!/usr/bin/ruby

# Parse https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php
# into lines suitable for passing to make_issue

def issue_from (line)
  return unless m = line.match( /(\d+) => '(.*)',?\s?$/ )
  return {
    id: m[1],
    text: m[2].gsub("'", "&rsquo;"),
  }
end

def parse_twfy_list (page)
  text = open(page).read
  return text[/protected \$policies = array\((.*?)\);$/m, 1].split(/\n/).map { |line|
    issue_from(line)
  }.reject { |p| p.nil? }
end


file = ARGV[0] || "twfy.policies.text"
parse_twfy_list(file).each do |i|
  puts "./make_issue.rb #{i[:id]} '#{i[:text]}' > issues/#{i[:id]}.json"
end



#!/usr/bin/ruby

# Generate Issues in Stancer format
# Usage: bin/generate_stancer_data.rb data/policies/*.json > stancer.json
#
# Quick 'n' dirty test until this moves somewhere better:
#   bin/generate_stancer_data.rb data/policies/1027.json > /tmp/1027.json
#   diff t/1027.json /tmp/1027.json

require 'json'

# The MP’s votes count towards a weighted average where the most important
# votes get 50 points, less important votes get 10 points, and less
# important votes for which the MP was absent get 2 points. In important
# votes the MP gets awarded the full 50 points for voting the same as the
# policy, no points for voting against the policy, and 25 points for not
# voting. In less important votes, the MP gets 10 points for voting with
# the policy, no points for voting against, and 1 (out of 2) if absent.
#   http://www.publicwhip.org.uk/mp.php?mpid=40665&dmp=1027

# Strong: majority: 50 / absent: 25 / minority: 0
# Normal: majority: 10 / absent: 1  / minority: 0

def weights_for (aspect)
  strong = !!aspect['direction'][/\(strong\)/]

  # This can undoubtedly be simplified, but let's be really explicit
  direction = aspect['direction']

  if direction.downcase.include? 'majority'
    majority_vote = aspect['motion']['result'] == 'passed' ? "yes" : "no"
    minority_vote = aspect['motion']['result'] == 'passed' ? "no" : "yes"
  elsif direction.downcase.include? 'minority'
    majority_vote = aspect['motion']['result'] == 'failed' ? "yes" : "no"
    minority_vote = aspect['motion']['result'] == 'failed' ? "no" : "yes"
  elsif direction.downcase.include? 'abstain'
    abort "Should skip abstains"
  else
    abort "Aspect has no direction"
  end

  if (strong) 
    return { 
      majority_vote => 50,
      'absent'      => 25,
      'both'        => 25,
      minority_vote => 0,
    }
  else
    return { 
      majority_vote => 10,
      'absent'      => 1,
      'both'        => 1,
      minority_vote => 0,
    }
  end
end


def aspects_from (aspects)
  aspects.reject { |aspect| 
    aspect['direction'].downcase.include? 'abstain' 
  }.map { |aspect|
    {
      motion_id: aspect['motion']['id'],
      result: aspect['motion']['result'],
      direction: aspect['direction'],
      weights: weights_for(aspect),
    }
  }
end

issues = ARGV.map do |filename|
  warn "Parsing #{filename}"
  policy = JSON.parse(File.read(filename))
  { 
    # policy: policy
    id: "PW-" + policy['sources'][0]['url'][/policy.php\?id=(\d+)/, 1],
    text: policy['text'],
    html: policy['description'],
    categories: policy['categories'],
    aspects: aspects_from(policy['aspects']),
  }
end

puts JSON.pretty_generate(issues)

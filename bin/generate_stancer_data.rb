#!/usr/bin/ruby

# Generate Issues in Stancer format
# Usage: bin/generate_stancer_data.rb data/policies/*.json > stancer.json

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
  majority_vote = aspect['motion']['result'] == 'passed' ? "yes" : "no"
  minority_vote = aspect['motion']['result'] == 'passed' ? "no" : "yes"
  strong = !!aspect['direction'][/\(strong\)/]

  if (strong) 
    return { 
      majority_vote => 50,
      'absent'  => 25,
      minority_vote => 0,
    }
  else
    return { 
      majority_vote => 10,
      'absent'  => 1,
      minority_vote => 0,
    }
  end
end


def aspects_from (aspects)
  aspects.map { |aspect|
    {
      motion_id: aspect['motion']['id'],
      result: aspect['motion']['result'],
      direction: aspect['direction'],
      weights: weights_for(aspect),
    }
  }
end

issues = ARGV.map do |filename|
  policy = JSON.parse(File.read(filename))
  { 
    # policy: policy
    id: "PW-" + policy['sources'][0]['url'][/policy.php\?id=(\d+)/, 1],
    text: policy['text'],
    html: policy['description'],
    aspects: aspects_from(policy['aspects']),
  }
end

puts JSON.pretty_generate(issues)

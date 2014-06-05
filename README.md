# UK Vote Data

This generates data for use in a sample UK VoteIt

## Usage

1. Download the current TheyWorkForYou Policy list from https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php to ``data/twfy.policies.text``

2. ``bin/parse-mysoc-policies.rb data/twfy.policies.text``

3. The output of that is a series of ``make_issue.rb`` commands to scrape PublicWhip data and create Issue JSON for each Policy.

4. ``bin/parties_from_issues.rb issues/*.json > parties.json``

5. ``bin/people_from_issues.rb issues/*.json > people.json``

6. ``for i in issues/*.json; do; basename $i; bin/motions_from_issues.rb $i > data/motions/`basename $i`; done``

7. ``bin/generate_motion_file.rb data/motions/*.json > motions-all.json``

8. Load that to your voteit-api server


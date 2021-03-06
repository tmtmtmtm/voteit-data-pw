# UK Vote Data

Turn UK voting data from PublicWhip into JSON suitable for use with a
Stancer.

## Usage

1. Download the current TheyWorkForYou Policy list from https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php to ``data/twfy.policies.text``

2. ``bin/parse-mysoc-policies.rb data/twfy.policies.text``

3. The output of that is a series of ``scrape_policy_json.rb`` commands to scrape PublicWhip data and create Policy JSON for each Policy.

4. ``bin/parties_from_policies.rb data/policies/*.json > parties.json``

5. ``bin/people_from_policies.rb data/policies/*.json > people.json``

6. ``for i in data/policies/*.json; do; basename $i; bin/motions_from_policies.rb $i > data/motions/`basename $i`; done``

7. ``bin/generate_motion_file.rb data/motions/*.json > motions-all.json``

8. ``bin/generate_stancer_data.rb data/policies/*.json > issues.json``

9. Load motions-all.json and issues.json into your Stancer (e.g. [stancer-pw](https://github.com/tmtmtmtm/stancer-pw))

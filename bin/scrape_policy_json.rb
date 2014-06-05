#!/usr/bin/ruby

# Make a Policy JSON for a mySoc policy from PublicWhip data
# https://raw.githubusercontent.com/mysociety/theyworkforyou/master/classes/Policies.php
#
# Usage: $0 <id> <cats> <str>

require 'cgi'
require 'uri'
require 'colorize'

class PWScraper

  require 'json'
  require 'nokogiri'
  require 'open-uri/cached'
  OpenURI::Cache.cache_path = './cache'

  @@PW_URL = 'http://www.publicwhip.org.uk/'

  def initialize(page)
    page = @@PW_URL + page unless page.start_with? 'http'
    @page = page
    warn "Reading #{page}".green
    @doc = Nokogiri::HTML(open(page))
  end

  def as_hash
    return structure
  end

end

class DivisionScraper < PWScraper

  def structure 
    return { 
      id: "pw-#{motion_date}-#{motion_id}",
      organization_id: "uk.parliament.commons",
      text: bill,
      date: motion_date,
      sources: [{ url: pw_link }, { url: hansard }],
      result: result,
      date: motion_date,
      vote_events: [ vote_event ]
    }
  end

  def vote_event
    {
        start_date: datetime,
        counts: counts,
        votes: votes,
    }.reject { |k,v| v.nil? }
  end

  def bill
    h1_parts.first
  end

  def datetime
    # "19 Nov 2003 at 16:45",
    (date_s, time_s) = h1_parts.last.split(/ at /)
    return if time_s.nil?
    (hh, mm) = time_s.split(/:/).map(&:to_i)
    date = Date.strptime(date_s, '%d %b %Y')
    if hh > 24
      hh -= 24
      date += 1
    end
    return DateTime.new(date.year, date.mon, date.mday, hh, mm, 0) 
  end

  def h1_parts
    @doc.at_css('#main h1').text.strip.reverse.split('—', 2).reverse.map(&:strip).map(&:reverse)
  end

  def id
    "pw-#{motion_date}-#{motion_id}"
  end

  def motion_date
    CGI.parse(pw_link.query)['date'].first
  end

  def motion_id
    CGI.parse(pw_link.query)['number'].first
  end

  def constituency_link 
    @doc.xpath("//a[text()='Constituency']/@href").text
  end

  def pw_link
    URI.parse(@@PW_URL + constituency_link.gsub('&sort=constituency',''))
  end

  def votes
    @votes ||= @doc.css('#votetable tr').drop(1).map { |voterow| 
      row = voterow.css('td')
      (who, where, party, vote) = row.map(&:text).map(&:strip)
      mpurl = row[0].xpath('./a/@href').first
      person = {
        name: who,
        url: @@PW_URL + mpurl,
        constituency: where,
        party: party
      }
      vote = {
        voter: person,
        option: vote,
      }
      if (vote[:option].start_with? 'tell')
        vote[:role] = 'teller'
        vote[:option].gsub!(/^tell/,'')
      end
      vote[:option] = 'yes' if vote[:option] == 'aye'
      vote
    }
  end

  def counts
    votes.group_by { |v| v[:option] }.map { |k,v| { option: k, value: v.count } }
  end

  def result
    (ys, ns) = %w(yes no).map { |want|
      counts.find { |c| c[:option] == want }[:value]
    }
    result = ys > ns ? "passed" : "failed"
  end

  def hansard
    hansard = @doc.xpath("//a[text()='Online Hansard']/@href").text
    hansard = @doc.xpath("//a[text()='Source']/@href").text if hansard.empty?
    raise "No hansard record in #{@page}" if hansard.empty?
    return hansard
  end
end

class PolicyScraper < PWScraper

  def structure 
    return { 
      text: policy_text,
      sources: [{ url: @page }],
      aspects: aspects.reject { |a| a.nil? }
    }
  end

  def policy_text
    policy = @doc.at_css('#main h1').text.strip
    policy_text = policy[/Policy #(\d+): "([^:]+)"/, 2]
    abort "No policy_text in #{policy}" if policy_text.empty?
    policy_text
  end

  def aspects
    @doc.css('table.votes tr').drop(1).map { |prow|
      row = prow.css('td')
      (house, date, subject, direction) = row.map(&:text).map(&:strip)
      next unless house == 'Commons'
      votepage = row[2].xpath('./a/@href').first.text + '&display=allpossible'

      {
        direction: direction,
        source: @@PW_URL + votepage,
        motion: DivisionScraper.new(votepage).as_hash,
      }
    }
  end
end

#----------------

abort "Usage: $0 <id> <cats> <description>" unless ARGV.count == 3

policy = PolicyScraper.new("policy.php?id=" + ARGV[0]).as_hash
policy[:categories] = ARGV[1].split /,/
policy[:description] = ARGV[2]
puts JSON.pretty_generate(policy)



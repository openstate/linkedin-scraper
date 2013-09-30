#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'httparty'
require 'linkedin'
require 'inifile'

def serialize_profile(profile)
  info = {
    :first_name => profile.first_name,
    :last_name => profile.last_name
  }
  
  begin
    info[:distance] = profile.distance    
  rescue Exception => e
    info[:distance] = 1 # default ...
  end
  
  begin
    info[:companies] = profile.positions.all.map{|t| t.company}
  rescue Exception => e
    info[:companies] = []
  end
  
end

def scrape_person(connections, depth, client, cached_profiles)
  new_profiles = {}
  i = 0
  connections[:all].each do |connection|
    i += 1
    next if i > 5
    next if cached_profiles.has_key?(connection.id)
    full_connection = client.profile(:id => connection.id, :fields => %w(positions connections))
    puts full_connection.connections
    new_profiles[connection.id] = full_connection

    begin
      companies = full_connection.positions.all.map{|t| t.company}
      company_name = companies[0].name
    rescue Exception => e
      company_name = "<unknown>"
    end

    #puts full_connection.inspect
    puts [
      depth,
      #{}"%s %s" % [profile.first_name, profile.last_name],
      "%s %s" % [connection.first_name, connection.last_name],
      connection.industry,
      company_name
    ].join(",")
    sleep(1)
  end
  
  new_profiles
end

inifile = IniFile.new( :filename => 'linkedin.ini', :encoding => 'UTF-8' )
#puts inifile.inspect

# get your api keys at https://www.linkedin.com/secure/developer
client = LinkedIn::Client.new(inifile['application']['key'], inifile['application']['secret'])
rtoken = client.request_token.token
rsecret = client.request_token.secret

# to test from your desktop, open the following url in your browser
# and record the pin it gives you
#puts client.request_token.authorize_url
#=> "https://api.linkedin.com/uas/oauth/authorize?oauth_token=<generated_token>"

#pin = gets

# then fetch your access keys
#auth_token, auth_secret = client.authorize_from_request(rtoken, rsecret, pin)
auth_token = inifile['user']['token']
auth_secret = inifile['user']['secret']
client.authorize_from_access(auth_token, auth_secret)

#puts client.profile.inspect

#puts client.connections.inspect

profiles = []
client.connections[:all].each do |connection|
  profiles << serialize_profile(connection)
end

#cached_profiles = scrape_person(client.connections, 1, client, {})
#second_level_profiles = cached_profiles.values

offset = 0
total = 100
while (offset < total) do
  results = client.search(
    :start => offset,
    :fields => [{ :people => %w(id first-name last-name api-standard-profile-request distance relation-to-viewer)}],
    :facet => 'network,S'
  )

  total = results[:people][:total]
  results[:people][:all].each do |result|
    begin
      profile = client.profile(:id => result[:id], :fields => %w(positions relation-to-viewer:(related-connections:(first_name,last_name))))
      #puts profile.inspect
      #puts "%s %s" % [result[:first_name], result[:last_name]]
      puts result[:relation_to_viewer].keys.inspect
      profiles << serialize_profile(result)      
    rescue Exception => e
      
    end
    
  end
  offset = offset + results[:people][:all].length
  sleep(1)
end

puts JSON.generate(profiles)
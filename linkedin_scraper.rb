#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'httparty'
require 'linkedin'
require 'inifile'

def serialize_profile(profile)
  info = {
    :id => profile.id,
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

  info
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
client.connections(:fields => %w(id first-name last_name positions))[:all].each do |connection|
  profiles << serialize_profile(connection)
end

#cached_profiles = scrape_person(client.connections, 1, client, {})
#second_level_profiles = cached_profiles.values

offset = 0
total = 100
while (offset < total) do
  results = client.search(
    :start => offset,
    :fields => [{ :people => %w(id first-name last-name api-standard-profile-request distance relation-to-viewer positions)}],
    :facet => 'network,S'
  )

  total = results[:people][:total]
  #puts results.inspect
  results[:people][:all].each do |result|
    begin
      profile = client.profile(:id => result[:id], :fields => %w(relation-to-viewer))
      #puts "%s %s" % [result[:first_name], result[:last_name]]
      #puts result[:relation_to_viewer].keys.inspect
      info = serialize_profile(result)
      begin
        info[:connections] = profile.relation_to_viewer.connections.all.map { |connection| serialize_profile(connection.person) }        
      rescue Exception => e
        info[:connections] = []
      end
      #puts JSON.generate(info)
      profiles << info
    rescue Exception => e
      
    end
    
  end
  offset = offset + results[:people][:all].length
  sleep(1)
end

puts JSON.generate(profiles)
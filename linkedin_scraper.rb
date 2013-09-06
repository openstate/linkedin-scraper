#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'httparty'
require 'linkedin'
require 'inifile'

inifile = IniFile.new( :filename => 'linkedin.ini', :encoding => 'UTF-8' )
puts inifile.inspect

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

puts client.profile.inspect

puts client.connections.inspect
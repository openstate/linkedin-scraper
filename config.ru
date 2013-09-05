require 'rubygems'
require 'sinatra'

require File.expand_path('../linkedin_scraper', __FILE__) 

run Sinatra::Application

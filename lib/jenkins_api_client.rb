require 'rubygems'
require 'json'
require 'net/http'
require 'base64'
require 'nokogiri'
require 'active_support/core_ext'
require 'active_support/builder'
require 'pp'

require File.expand_path('../jenkins_api_client/client', __FILE__)

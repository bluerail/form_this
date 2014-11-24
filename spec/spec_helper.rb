ENV["RAILS_ENV"] ||= 'test'
require 'rubygems'
require 'bundler/setup'

require 'active_model'
require 'active_record'
require 'active_support'

require 'virtus'

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].sort.each { |f| require f }

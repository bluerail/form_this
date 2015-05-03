ENV["RAILS_ENV"] ||= 'test'
require 'rubygems'
require 'bundler/setup'

require 'active_model'
require 'active_record'
require 'active_support'
require 'active_support/all'

require 'virtus'
require 'factory_girl'
require 'faker'

Dir["#{File.dirname __FILE__}/../lib/**/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname __FILE__}/models/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname __FILE__}/factories/*.rb"].sort.each { |f| require f }

# TODO: Order matters.. We would prefer to just autoload..
%w(base comment genre track album artist) .each do |f|
  require "#{File.dirname __FILE__}/forms/#{f}_form.rb"
end

# Shuts up some warnings/messages
I18n.enforce_available_locales = false
ActiveRecord::Migration.verbose = false

# Setup our database
ActiveRecord::Base.configurations = {'test' => {adapter: 'sqlite3', database: ':memory:'}}
ActiveRecord::Base.establish_connection :test

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.order = "random"
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before(:suite) do
    ActiveRecord::Tasks::DatabaseTasks.create_all
    load "#{File.dirname __FILE__}/schema.rb"
  end
end

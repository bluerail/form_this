ENV["RAILS_ENV"] ||= 'test'
require 'rubygems'
require 'bundler/setup'

require 'active_model'
require 'active_record'
require 'active_support'

require 'virtus'

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].sort.each { |f| require f }

# Shuts up some warnings
I18n.enforce_available_locales = false

module FormThisSpecHelper
  @@n = 0

  class TestRecord
    include ActiveModel::Model

    def initialize attr={}
      attr.each { |k, v| send("#{k}=", v) }
      super()
    end


    def method_missing m, *args
      if m.to_s.end_with? '='
        instance_variable_set "@_#{m[0..-2]}", args[0]
      else
        instance_variable_get "@_#{m}"
      end
    end
  end


  def make_form *props, **opts
    @@n += 1

    eval("class TestForm#{@@n} < FormThis::Base
      #{opts[:eval] || ''}
    end")
    klass = Object.const_get "FormThisSpecHelper::TestForm#{@@n}"
    klass.properties(*props, **opts)
    return klass.new TestRecord.new
  end
end

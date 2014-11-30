ENV["RAILS_ENV"] ||= 'test'
require 'rubygems'
require 'bundler/setup'

require 'active_model'
require 'active_record'
require 'active_support'

require 'virtus'

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].sort.each { |f| require f }

module FormThisSpecHelper
  @@n = 0
  #class TestForm < FormThis::Base
  #end

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


  def make_form ev, *props
    @@n += 1

    eval("class TestForm#{@@n} < FormThis::Base
      #{ev}
    end")
    klass = Object.const_get "FormThisSpecHelper::TestForm#{@@n}"
    klass.properties(*props)
    return klass.new TestRecord.new
  end
end

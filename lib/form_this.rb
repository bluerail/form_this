#
# https://github.com/bluerail/form_this
#
# Copyright © 2014-2015 LICO Innovations
# See below for full copyright
#

require 'virtus'

module FormThis
  # If you're using +FormThis+, you almost never want to pass an +ActiveRecord+
  # instance to +form_for+, doing so can lead to strange behaviour, strange
  # errors, and -worst of all- invalid data in your database.
  #
  # This "protects" +form_for+ and will raise an +Exception+ if we pass in
  # anything other than a +FormThis::Base+ instance.
  #
  # This can be disabled by setting +FormThis.protect_form_for+ to +false+.
  mattr_accessor :protect_form_for
  @@protect_form_for = true


  # Validations are now on a Form object, and it's fairly easy to create a
  # "corrupt" record with +SomeRecord.create(name: 'xxx')+.
  # 
  # This will "protect" +save+, +create+, and +update+ (and their !-variants)
  mattr_accessor :protect_active_record
  @@protect_active_record = true


  # Formtastic uses the name of the foreign key, which usually won't be the same
  # name as what we use in a form object.
  mattr_accessor :foreign_key_aliases
  @@foreign_key_aliases = true


  class Base
    include Virtus.model
    include ActiveModel::Model


    # Every form object has an ActiveRecord instance associated with it.
    attr_accessor :record

    # Store all properties & options
    class_attribute :defined_properties
    self.defined_properties = {}.with_indifferent_access


    # Delegate some methods to the record
    # - +id+ & +persisted?+ are required for +form_for+;
    # - +column_for_attribute+ allows +Formtastic+ to guess the input type
    #   (TODO: deprecated in Rails 5)
    # - +new_record?+ is just for convenience.
    delegate :id, :persisted?, :column_for_attribute, :has_attribute?, :new_record?, to: :record


    # Manually set the model name, normally this is inferred from the class name
    # The convention is to use +ModelNameForm+, and +ModelNameForm_NestedModel+
    # for nested forms that are used only with this form (you can use any form
    # class as a nested form).
    def self.model name
      @_model_name = name.to_s
    end


    # Get the model name; we need this for +form_for+.
    def self.model_name
      ::ActiveModel::Name.new self, nil,
        @_model_name || self.name.split('_').pop.sub(/Form$/, '')
    end


    # Call +@record.reflect_on_association+; this allows Formtastic to populate
    # select fields for associations
    def self.reflect_on_association assoc
      Object.const_get(self.model_name.name).reflect_on_association assoc
    end


    # Use the i18n keys from ActiveRecord.
    def self.i18n_scope
      :activerecord
    end


    # Define a property; the +name+ is mandatory, all other options are
    # optional:
    #
    # type::
    # If the +type+ is an ActiveRecord model, assume this is a +has_one+ or
    # +belongs_to+ association. If an integer is passed, we try to find this
    # record from the database.
    #
    # If the type is an FormThis instance, we assume this is a "nested" record,
    # and works as +accepts_nested_attributes_for+
    #
    # Anything else will passed on to the record (+record.send name+)
    #
    # You can use +Array[SomeModel]+ or +Array[SomeForm_Nested]+ to allow
    # multiple instances.
    #
    # +type+ defaults to +String+
    #
    # validates::
    # ActiveRecord validation.
    #
    # virtus::
    # Additional options to pass to Virtus.
    def self.property name, opts={}
      self.defined_properties[name] = opts
      self.attribute name, opts[:type] || String, opts[:virtus] || {}
      self.validates name, opts[:validates] if opts[:validates]

      # has_one or belongs_to, and allow attributes
      if self.is_form_this? opts[:type]
        self._property_has_one_form name
      # has_one or belongs_to, and *don't* allow attributes
      elsif self.is_model? opts[:type]
        self._property_has_one_record name, opts[:type]
      # has_many, and allow attributes
      elsif self.is_nested? opts[:type]
        self._property_has_many_forms name, opts[:type]
      # has_many, and *don't* allow attributes
      elsif self.is_model_list? opts[:type]
        self._property_has_many_records name
      end
    end


    # Define multiple properties; this can be used in various ways:
    #
    # Without any options:
    #   properties :street, :number
    #
    # Assign a different type for +postal_code+:
    #   properties :street, :number, postal_code: { type: String, validates: { presence: true } }
    #
    # Assign the same type & validations to all the properties:
    #   properties :street, number, type: String, validates: { presence: true }
    def self.properties *names, **names_with_opts
      params = {}
      names_with_opts.each do |name, v|
        case name.to_sym
          when :type
            params[:type] = v
          when :validates
            params[:validates] = v
          else
            self.property name, v
        end
      end

      names.each { |name| self.property name, params }
    end


    # Check if +klass+ inherits from +FormThis::Base+, but without creating an
    # instance of the class
    def self.is_form_this? klass
      return klass.is_a? FormThis::Base unless klass.is_a? Class

      while true
        return false unless klass.respond_to? :superclass
        return true if klass == FormThis::Base
        klass = klass.superclass
      end
    end
    def is_form_this? klass; self.class.is_form_this? klass end


    # Check if +klass+ extends +ActiveRecord::Persistence+
    def self.is_model? klass
      (klass.is_a?(Class) ? klass : klass.class).singleton_class.included_modules.include? ActiveRecord::Persistence::ClassMethods
    end
    def is_model? klass; self.class.is_model? klass end


    # Check if +klass+ is a list of models
    def self.is_model_list? klass
      klass.is_a?(Array) && self.is_model?(klass[0])
    end
    def is_model_list? klass; self.class.is_model_list? klass end


    # Check if +klass+ is a nested form
    def self.is_nested? klass
      klass.is_a?(Array) && self.is_form_this?(klass[0])
    end
    def is_nested? klass; self.class.is_nested? klass end


    # Get the model class of the record
    def self.model_class
      Object.const_get self.model_name.name
    end
    def model_class; self.class.model_class end


    # Get the contents as a formatted string
    def inspect
      "#<#{self.class} #{self.attributes.map { |k, v| "#{k}: #{self.attribute_for_inspect v}" }.join ', '}>"
    end


    # From Rails
    def attribute_for_inspect value
      if value.is_a?(String) && value.length > 50
        "#{value[0, 50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_s(:db)}")
      elsif value.is_a?(Array) && value.size > 10
        %(#{value.first(10).inspect[0...-1]}, ...])
      else
        value.inspect
      end
    end


    # We always have to start with an ActiveRecord::Base instance; we copy the
    # attributes from this AR instance to the form object
    def initialize record
      raise "You must initialize FormThis::Base with an ActiveRecord::Base instance, but you passed a `#{record.class}' (`#{record}') to #{self.class}" unless self.is_model? record

      @record = record
      attrs = {}
      self.set_defaults  # TODO: Make it a callback

      # Make sure we never modify anything in the DB here
      # TODO: Using a transaction here is a bit ugly, and causes (potentially
      # confusing) BEGIN/ROLLBACK messages in the log
      @record.transaction do
        # TODO: Allow attributes which aren't in the record
        self.attributes.each { |k, v| attrs[k] = @record.send k }
        super attrs
        raise ActiveRecord::Rollback
      end

      return self
    end
    # You can override this in your class to set defaults on +@record+; it is
    # executed after +@record+ is set, and before the +@record+ attributes are
    # copies to the form class.
    def set_defaults; end


    # Is this form valid? Also check all nested forms
    def valid? context=nil
      valid = super
      self.execute_for_all_forms(false) do |form, name|
        v = form.valid? context

        # Skip if reject_if callback is true
        # TODO: Allow symbols, and a shortcut for REJECT_ALL_BLANK_PROC
        if name && self.defined_properties[name][:reject_if].present? && self.defined_properties[name][:reject_if].call(form.attributes)
          next
        end

        valid = valid && v
      end
      return valid
    end


    # Assign values to the form object, and run validations.
    #
    # +params+ are the parameters the user filled in in the form; you usually use
    # something like:
    #
    #   @form.validate(params[:myobject]) && @form.save
    #
    # +_parent+ is used to the set the parent form object; this is used
    # internally and should not be set in an application.
    #
    # We silently skip if we don't know this attribute; this is the same
    # behaviour as strong parameters.
    def validate params, _parent=nil
      @parent = _parent
      unpermitted = []

      # First set all non-nested attributes; then set the nested. This way we
      # can access the parameter from the parent from the nested record
      params.each do |k, v|
        next if k.to_s.end_with? '_attributes'
        next unpermitted << k unless self.respond_to? "#{k}="
        self.send "#{k}=", v
      end

      # Set nested forms
      params.each do |k, v|
        next unless k.to_s.end_with? '_attributes'
        next unpermitted << k unless self.respond_to? "#{k}="

        # k is the following function:
        #
        # define_method "#{name}_attributes=" do |params|
        #   self.send(name).validate params
        # end
        self.send "#{k}=", v
      end

      # We tried to set an unknown/unpermitted attribute
      if unpermitted.length > 0
        if defined? ActionController
          case ActionController::Parameters.action_on_unpermitted_parameters
            when :log
              ActiveSupport::Notifications.instrument 'unpermitted_parameters.action_controller',
                keys: unpermitted
            when :raise
              raise ActionController::UnpermittedParameters.new unpermitted
          end
        else
          puts "==> WARNING Unpermitted parameters assigned: #{unpermitted.join ', '}"
        end
      end

      return self.valid?
    end


    # Execute the code in +&block+ for +self+ and all nested forms.
    # Parameters passed are the form object and the name of the relation
    def execute_for_all_forms including_self=true, &block
      block.call self, nil if including_self

      self.attributes.each do |name, v|
        if self.is_form_this? v
          block.call v, name, self
          v.execute_for_all_forms false, &block
        elsif self.is_nested? v
          v.each do |nested_form|
            block.call nested_form, name, self
            nested_form.execute_for_all_forms false, &block
          end
        end
      end
    end


    # Copy the data from the form class to the record; this does *not* persist
    # anything to the database, that is done by +persist!+.
    def update_record
      self.execute_for_all_forms(false) do |form|
        form.update_record
      end

      self.attributes.each do |name, v|
        next if self.is_nested?(v) || self.is_form_this?(v)
        next if name.to_sym == :_destroy
        @record.send "#{name}=", v
      end
    end


    # Persist the record to the database. You usually want to call
    # +update_record+ before calling this.
    # This *only* persists +@record+, and *not* nested forms.
    def persist!
      @record.transaction do
        success = true

        self.execute_for_all_forms(false) do |form, name, parent|
          # TODO: Allow symbols, and a shortcut for REJECT_ALL_BLANK_PROC
          if form._destroy
            success = success && form.record.destroy
          elsif name && parent.defined_properties[name][:reject_if].present? && parent.defined_properties[name][:reject_if].call(form.attributes)
            parent.send "#{name}=", nil
            parent.record.send "#{name}=", nil
            next
          else
            success = success && form.record.save
          end
        end

        success = success && @record.save

        raise ActiveRecord::Rollback unless success
        next success
      end
    end


    # Call +update_record+ & +persist!+. Return +false+ on failure.
    def save
      self.valid? && self.update_record && !!self.persist!
    end


    # Call +save+ and raise +ActiveRecord::RecordNotSaved+ if it fails.
    def save!
      self.save || raise(ActiveRecord::RecordNotSaved.new(nil, self))
    end


    # Try to find an AR from +record+, which may be an AR instance, the record
    # id, or nil; we expect the +type+ to be an AR class.
    def find_record record, type
      if record == '' || record.nil?
        nil
      elsif self.is_model? record
        record
      elsif record.respond_to?(:to_i) && record.to_i > 0
        type.find record.to_i
      else
        raise TypeError, "Can't find a `#{type}' record from `#{record}'"
      end
    end

    private

      # Helper for +self.property+, +has_one+ or +belongs_to+ associations.
      def self._property_has_one_form name
        define_method "#{name}_attributes=" do |params|
          self.send(name).validate params, self
        end
      end


      # Helper for +self.property+, +has_one+ or +belongs_to+ associations.
      def self._property_has_one_record name, type
        define_method "#{name}=" do |record|
          super self.find_record(record, type)
        end

        # Formtastic uses the name of the foreign key, which usually won't be
        # the same name as what we use in a form object
        if FormThis.foreign_key_aliases
          refl = self.reflect_on_association name
          if refl
            define_method(refl.foreign_key) { self.send(name).try :id }
            define_method("#{refl.foreign_key}=") { |v| self.send "#{name}=", v }
          end
        end
      end


      # Helper for +self.property+, +has_many+ associations.
      def self._property_has_many_forms name, type
        # Allow attributes
        if self.is_form_this? type.first
          self._property_has_many_with_attributes name, type
        # Don't allow attributes
        elsif self.is_model? type.first
          define_method "#{name}_attributes=" do |params|
            !params.values.map.with_index do |v, id|
              super self.find_record(v, type)
            end.include? false
          end
        # Does assigning an Array[String] ever make sense?
        else
          raise 'You need to use FormThis::Base or ActiveRecord::Base'
        end
      end


      # Helper for +self.property+, +has_many+ associations.
      def self._property_has_many_records name
        method = "#{name.to_s.singularize}_ids"
        define_method(method) { self.send(name).map(&:id) }
        define_method("#{method}=") do |val|
          model = Object.const_get name.to_s.singularize.camelize
          self.send "#{name}=", val.reject(&:blank?).map { |v| model.find v }
        end
      end


      # Helper for +self.property+, +has_many+ associations, with attributes.
      def self._property_has_many_with_attributes name, type
        define_method "#{name}_attributes=" do |params|
          # TODO: I'm not sure if the logic here is exactly the same as what AR
          # does; for example, we get a params hash which might look like:
          # {
          #   "0" => {"name"=>"test"},
          #   "3" => {"name"=>"another test"}
          # }
          #
          # Where do these keys come from (specifically, '3')?
          existing = self.send name
          !params.values.map.with_index do |v, id|
            if id >= existing.length
              self.send(name) << type.first.new(type.first.model_class.new).tap { |a| a.validate v, self }
            else
              existing[id].validate v, self
            end
          end.include? false
        end
      end


    # We always have a _destroy property
    self.property :_destroy, type: Boolean
  end
end


# Patch +form_for+ for the +FormThis.protect_form_for+ option.
if defined? ActionView
  module ActionView
    module Helpers
      module FormHelper
        # Save the original +form_for+
        alias __original_form_for__ form_for

        def form_for record, options = {}, &block
          if FormThis.protect_form_for
            case record
              when String, Symbol
                object = record
              else
                object = record.is_a?(Array) ? record.last : record
            end

            if !options[:skip_protection] && !FormThis::Base.is_form_this?(object)
              raise 'You need to pass a FormThis::Base object to form_for. ' +
                "You get this error because `FormThis.protect_form_for' is enabled."
            end
          end

          __original_form_for__ record, options, &block
        end
      end
    end
  end
end

# Patch ActiveRecord for the +FormThis.protect_active_record+ option.
#module ActiveRecord
#  module Persistence
#    module ClassMethods
#      alias __original_create__ create
#      alias __original_save__ save
#      alias __original_update__ update
#
#      def save(*)
#        super
#      end
#
#      def update(*)
#        super
#      end
#
#      def create(*)
#        super
#      end
#    end
#  end
#end


# Copyright © 2014-2015 LICO Innovations
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# vim:expandtab:ts=2:sts=2:sw=2

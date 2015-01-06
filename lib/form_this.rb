require 'virtus'

module FormThis
  mattr_accessor :protect_form_for
  mattr_accessor :foreign_key_aliases
  @@protect_form_for = true
  @@foreign_key_aliases = true


  class Base
    include Virtus.model
    include ActiveModel::Model


    # Every form object has an ActiveRecord instance associated with it.
    attr_accessor :record


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
      attribute name, opts[:type] || String, opts[:virtus] || {}
      validates name, opts[:validates] if opts[:validates]

      # has_one or belongs_to, and allow attributes
      if self.is_form_this? opts[:type]
        define_method "#{name}_attributes=" do |params|
          self.send(name).validate params
        end
      # has_one or belongs_to, and *don't* allow attributes
      elsif self.is_model? opts[:type]
        self._property_has_one name, opts[:type]

        # Formtastic uses the name of the foreign key, which usually won't be
        # the same name as what we use in a form object
        if FormThis.foreign_key_aliases
          refl = self.reflect_on_association name
          if refl
            define_method(refl.foreign_key) { self.send(name).try :id }
            define_method("#{refl.foreign_key}=") { |v| self.send "#{name}=", v }
          end
        end
      # has_many, and allow attributes
      elsif self.is_nested? opts[:type]
        self._property_has_many name, opts[:type]
      # has_many, and *don't* allow attributes
      elsif self.is_model_list? opts[:type]
        method = "#{name.to_s.singularize}_ids"
        define_method(method) { self.send(name).map(&:id) }
        define_method("#{method}=") do |val|
          model = Object.const_get name.to_s.singularize.camelize
          self.send "#{name}=", val.reject(&:blank?).map { |v| model.find v }
        end
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
      names_with_opts.each do |k, v|
        case k.to_sym
          when :type
            params[:type] = v
          when :validates
            params[:validates] = v
          else
            self.property k, v
        end
      end

      names.each { |n| self.property n, params }
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


    # Check if +klass+ extends +ActiveModel::Naming+
    # TODO: This returns True for both FormThis objects & AR objects; fixing
    # this seems to break stuff...
    def self.is_model? klass
      (klass.is_a?(Class) ? klass : klass.class).singleton_class.included_modules.include? ActiveModel::Naming
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


    # We always have to start with an ActiveRecord::Base instance; we copy the
    # attributes from this AR instance to the form object
    def initialize record
      raise "You must initialize FormThis::Base with an ActiveModel::Naming instance, but you passed a `#{record.class}' (`#{record}') to #{self.class}" unless self.is_model? record

      @record = record
      attrs = {}
      # TODO: Make it a callback
      self.set_defaults

      # Make sure we never modify anything in the DB here
      @record.transaction do
        self.attributes.each { |k, v| attrs[k] = @record.send k }
        super attrs
        raise ActiveRecord::Rollback
      end

      return self
    end
    def set_defaults; end


    # You can override this in your class to set defaults on +@record+; it is
    # executed after +@record+ is set, and before the +@record+ attributes are
    # copies to the form class.
    #

    # Call +@record.id+; we need this for +form_for+.
    def id
      @record.id
    end


    # Call +@record.persisted?+; we need this for +form_for+.
    def persisted?
      @record.persisted?
    end


    # Call +@record.new_record?+
    def new_record?
      @record.new_record?
    end


    # Call +@record.column_for_attribute+; this allows Formtastic to guess the
    # input typpe
    def column_for_attribute name
      @record.column_for_attribute name
    end


    # Assign values to the form object, and run validations.
    #
    # +params+ are the parameters the user filled in in the form; you usually use
    # something like:
    #
    #   @form.validate(params[:myobject) && @form.save
    #
    # +_parent+ is used to the set the parent form object; this is used
    # internally and should not be set in an application.
    #
    # We silently skip if we don't know this attribute; this is the same
    # behaviour as strong parameters.
    # TODO: Also log this, like strong parameters does
    def validate params, _parent=nil
      @parent = _parent
      valid = true

      params.each do |k, v|
        next if k.to_s.end_with? '_attributes'
        next unless self.respond_to? "#{k}="
        self.send "#{k}=", v
      end

      # First set all non-nested attributes; then set the nested. This way we
      # can access the parameter from the parent from the nested record

      # Set nested records
      params.each do |k, v|
        next unless k.to_s.end_with? '_attributes'
        next unless self.respond_to? "#{k}="

        # k is the following function:
        #
        # define_method "#{name}_attributes=" do |params|
        #   self.send(name).validate params
        # end
        r = self.send "#{k}=", v
        valid = r && valid
      end

      return self.valid? && valid
    end


    # Execute the code in +&block+ for +self+ and all nested forms.
    def execute_for_all_forms including_self=true, &block
      block.call self if including_self
      self.attributes.each do |k, v|
        if self.is_form_this? v
          block.call v
          v.execute_for_all_forms(true, &block)
        elsif self.is_nested? v
          v.each { |n| n.execute_for_all_forms(true, &block) }
        end
      end
    end


    # Copy the data from the form class to the record; this does *not* persist
    # anything to the database, that is done by +persist!+.
    def update_record
      self.attributes.each do |k, v|
        next if self.is_nested?(v) || self.is_form_this?(v)

        # TODO: Make this an option
        if k == :_destroy
          self.record.destroy if v.present?
          next
        end

        @record.send "#{k}=", v
      end
    end


    # Persist the record to the database. You usually want to call
    # +update_record+ before calling this.
    def persist!
      @record.save
    end


    # Call +update_record+ & +persist!+. Return +false+ on failure.
    def save
      self.update_record
      self.persist!
    end


    # Call +save+ and raise +ActiveRecord::RecordNotSaved+ if it fails.
    def save!
      self.save || raise(ActiveRecord::RecordNotSaved.new(nil, self))
    end


    # Try to find an AR from +record+, which may be an AR instance, the record
    # id, or nil; we expect the +type+ to be an AR class.
    def find_record record, type
      if record == ''
        nil
      elsif self.is_model? record
        record
      elsif record.respond_to?(:to_i) && record.to_i > 0
        type.find record.to_i
      else
        record
      end
    end


    private

      # Helper for +self.property+, +has_one+ or +belongs_to+ associations.
      def self._property_has_one name, type
        define_method "#{name}=" do |record|
          super self.find_record(record, type)
        end
      end


      # Helper for +self.property+, +has_many+ associations.
      def self._property_has_many name, type
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
  end
end


if defined? ActionView
  module ActionView
    module Helpers
      module FormHelper
        # If you're using +FormThis+, you never want to pass an
        # +ActiveRecord+ instance to +form_for+, doing so can lead to strange
        # behaviour, strange errors, and -worst of all- invalid data in your
        # database.
        # This "protects" +form_for+ and will raise an +Exception+ if we pass in
        # anything other than a +FormThis::Base+ instance.
        #
        # This can be disabled by setting +FormThis.protect_form_for+ to +false+.
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

# vim:expandtab:ts=2:sts=2:sw=2

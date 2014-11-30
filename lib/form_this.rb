require 'virtus'

module FormThis
  class Base
    include Virtus.model
    include ActiveModel::Model


    # Every form object has an ActiveRecord instance associated with it.
    attr_accessor :record


    # Manually set the model name, normally this is inferred from the class name
    # The convention is to use +ModelNameForm+, and +ModelNameForm_NestedModel+
    # for nested records.
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
      refl = Object.const_get(self.model_name.name).reflect_on_association assoc
      if refl
        # Formtastic uses the name of the foreign key, which usually won't be
        # the same name as what we use in a form object
        define_method(refl.foreign_key) { self.send(assoc).try :id }
        define_method("#{refl.foreign_key}=") { |v| self.send "#{assoc}=", v }
      end
      return refl
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
    # You can use +Array[SomeModel]+ or +Array[SomeForm_Nested]+ to allow multiple instances.
    #
    # +type+ defaults to +String+
    #
    # validates:: ActiveRecord validation
    #
    # virtus:: Additional options to pass to Virtus
    def self.property name, opts={}
      attribute name, opts[:type] || String, opts[:virtus] || {}
      validates name, opts[:validates] if opts[:validates]

      # has_one or belongs_to, and allow attributes
      if self.is_form_this? opts[:type]
        define_method "#{name}_attributes=" do |params|
          self.send(name).validate params
        end
      # has_on or /belongs_to, and *don't* allow attributes
      elsif self.is_model? opts[:type]
        define_method "#{name}=" do |params|
          if self.is_model? params
            super params
          elsif params.to_i > 0
            super opts[:type].find params.to_i
          elsif params == ''
            super nil
          else
            super params
          end
        end
      # has_many associations
      elsif opts[:type].is_a? Enumerable
        # Allow attributes
        if self.is_form_this? opts[:type].first
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
                #self.albums << ArtistForm_Album.new(Album.new).tap { |a| a.validate v, self }
                self.send(name) << opts[:type].first.new(opts[:type].first.model_class.new).tap {|a| a.validate v, self }
              else
                existing[id].validate v, self
              end
            end.include? false
          end
        # Don't allow attributes
        elsif self.is_model? opts[:type].first
          define_method "#{name}_attributes=" do |params|
            !params.values.map.with_index do |v, id|
              if self.is_model? v
                super v
              elsif v.to_i > 0
                super opts[:type].find v.to_i
              else
                super v
              end
            end.include? false
          end
        # Does assigning an Array[String] ever make sense?
        else
          raise 'You need to use FormThis::Base or ActiveRecord::Base'
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
      while true
        return false unless klass.respond_to? :superclass
        return true if klass == FormThis::Base
        klass = klass.superclass
      end
    end


    # Check if +klass+ extends +ActiveModel::Naming+
    def self.is_model? klass
      (klass.is_a?(Class) ? klass : klass.class).singleton_class.included_modules.include? ActiveModel::Naming
    end


    def is_model? klass
      self.class.is_model? klass
    end


    # Get the model class of the record
    def self.model_class
      Object.const_get self.model_name.name
    end


    # We always have to start with an ActiveRecord::Base instance; we copy the
    # attributes from this AR instance to the form object
    def initialize record
      # TODO: Make this more duck-type-y
      raise 'Must be an ActiveModel::Naming instance' unless self.is_model? record

      @record = record
      self.set_defaults
      attrs = {}
      self.attributes.each { |k, v| attrs[k] = @record.send k }
      super attrs

      return self
    end


    # Get the model class of the record
    def model_class
      self.class.model_class
    end


    # You can override this in your class to set defaults on +@record+; it is
    # executed after +@record+ is set, and before the +@record+ attributes are
    # copies to the form class.
    #
    # TODO: First off, we want to be able to use:
    #   property :foo, default: 'bar'
    # TODO: Also, we want to use rails-y callbacks, ie.:
    #   before :initialize, -> { ... }
    #   after :initialize, -> { ... }
    def set_defaults
    end


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

      # First set all non-nested attributes; then set the nested. This way we
      # can access the parameter from the parent from the nested record
      params.each do |k, v|
        next if k.ends_with? '_attributes'
        next unless self.respond_to? "#{k}="
        self.send "#{k}=", v
      end

      # Set nested records
      params.each do |k, v|
        next unless k.ends_with? '_attributes'
        next unless self.respond_to? "#{k}="
        r = self.send "#{k}=", v
        valid = r && valid 
      end

      return self.valid? && valid
    end


    # Copy the data from the form class to the record; this does *not* persist
    # anything to the database, that is done by +persist!+.
    def update_record
      # Call update_record on nested records first
      # TODO: I forgot why I added this... If it's required, we need to do this
      # work for more than 1 level of nesting; I also don't know why only on
      # has_many nestings, and not has_one
      #self.attributes.each do |k, v|
      #    next unless v.is_a? Enumerable
      #    v.map { |r| r.update_record if r.id.present? }
      #end

      @record.update self.to_h
    end


    # Convert a form object to a hash acceptable for the +new+ & +update+ method
    # of +ActiveRecord+.
    def to_h
      convert_form_object = -> (form_object) do
        if form_object.is_a?(FormThis::Base) && form_object.id.present?
          form_object.model_class.find(form_object.id).tap { |set| set.update form_object.to_h }
        elsif form_object.is_a? FormThis::Base
          form_object.model_class.new form_object.to_h
        elsif form_object.is_a? Enumerable
          form_object.map { |obj| convert_form_object.call obj }
        end
      end

      self.attributes.inject({}) do |acc, (k, v)|
        acc[k] = v.is_a?(FormThis::Base) || v.is_a?(Enumerable) ?
          convert_form_object.call(v) : 
          v
        next acc
      end
    end


    # Persist the record to the database. You usually want to call
    # +update_record+ before calling this.
    def persist!
      success = true
      ActiveRecord::Base.transaction do
        # Call persist on nested records first
        self.attributes.each do |k, v|
            next unless v.is_a? Enumerable
            v.map { |r| success = r.save && success if r.id.present? }
        end

        return @record.save && success
      end
    end


    # Call +update_record+ & +persist!+. Return +false+ on failure.
    def save
      self.update_record
      self.persist!
    end


    # Call +save+, and raise a +RecordNotSaved+ exception on failure.
    def save!
      self.save || raise(RecordNotSaved)
    end
  end
end

require 'virtus'

module FormObjects
  class Base
    include Virtus.model
    include ActiveModel::Model

    attr_accessor :record


    # Manually set the model name
    def self.model name
      @_model_name = name
    end


    # Get the model name; used by form_for
    # The convention is to use ModelNameForm, and ModelNameForm_NestedModel for
    # nested objects
    def self.model_name
      ::ActiveModel::Name.new self, nil,
        @_model_name || self.name.split('_').pop.sub(/Form$/, '')
    end


    # Use the i18n keys from activerecord
    def self.i18n_scope
      :activerecord
    end


    # Define a property
    def self.property name, opts={}
      attribute name, opts[:type] || String
      validates name, opts[:validates] if opts[:validates]

      if self.has_superclass opts[:type]
        define_method "#{name}_attributes=" do |params|
          self.send(name).validate params
        end
      end

      if opts[:type].is_a? Enumerable
        define_method "#{name}_attributes=" do |params|
          # TODO: Is using the index from params as the index a good idea? Where
          # does this index come from anyway?
          !params.map { |id, v| self.send(name)[id.to_i].validate v, self }.include? false
        end
      end
    end


    # Define multiple properties
    #   properties :street, :number
    #   properties :street, :number, postal_code: { type: String, validates: { presence: true } }
    def self.properties *names, **names_with_opts
      names.each { |n| self.property n }
      names_with_opts.each { |k, v| self.property k, v }
    end


    # Helper method to check if a class has this class as a base, but without
    # creating an instance of the class
    def self.has_superclass klass
      while true
        return false unless klass.respond_to? :superclass
        return true if klass == FormObjects::Base
        klass = klass.superclass
      end
    end

    
    # Every form object is associated with an AR record
    def initialize record
      # TODO: Make this more duck-type-y
      raise 'Must be an ActiveRecord::Base instance' unless record.is_a? ActiveRecord::Base

      @record = record
      self.set_defaults
      attrs = {}
      self.attributes.each { |k, v| attrs[k] = @record.send k }
      super attrs

      return self
    end


    def model_class
      Object.const_get self.class.model_name.name
    end


    # Override this to set defaults on @record
    def set_defaults
    end


    # The id field always goes to the record, and can't be set manually
    def id
      @record.id
    end


    # TODO: Perhaps we also need to check for dependent records here?
    def persisted?
      @record.persisted?
    end


    # Set parameters, and check if all is valid
    def validate params, parent=nil
      @parent = parent
      valid = true

      # First set all non-nested attributes; then set the nested. This way we
      # can access the parameter from the parent from the nested record
      #
      # We silently skip if we don't know this attribute; this is the same
      # behavior as strong parameters
      # TODO: Also log this, like strong parameters does
      params.each do |k, v|
        next if k.ends_with? '_attributes'
        next unless self.respond_to? "#{k}="
        self.send "#{k}=", v
      end

      params.each do |k, v|
        next unless k.ends_with? '_attributes'
        next unless self.respond_to? "#{k}="
        r = self.send "#{k}=", v
        valid = r && valid 
      end

      return self.valid? && valid
    end


    # Copy the data from the form class to the record; does *not* actually
    # persist anything to the database
    def update_record
      # Call update_record on dependent records first
      self.attributes.each do |k, v|
          next unless v.is_a? Enumerable
          v.map { |r| r.update_record if r.id.present? }
      end

      attrs = {}
      # Convert Form object to a AR object if required
      # TODO: This could probably be a bit cleaner
      self.attributes.each do |k, v|
                   # Nested record (single), existing record
        attrs[k] = if v.is_a?(FormObjects::Base) && v.id.present?
                      set = v.model_class.find(v.id)
                      set.update v.attributes
                      set
                    # Nested record (single), new record
                    elsif v.is_a? FormObjects::Base
                      v.model_class.new v.attributes
                    # Nested records (many)
                    elsif v.is_a? Enumerable
                      v.map do |obj|
                        # Existing record
                        if obj.id.present?
                          set = obj.model_class.find(obj.id)
                          set.update obj.attributes
                          set
                        # New record
                        else
                          obj.model_class.new obj.attributes
                        end
                      end
                    # Value
                    else
                      v
                    end
      end

      @record.update attrs
    end


    # Persist the record to the database
    def persist
      success = true
      ActiveRecord::Base.transaction do
        # Call persist on dependent records first
        self.attributes.each do |k, v|
            next unless v.is_a? Enumerable
            v.map { |r| success = r.save && success if r.id.present? }
        end

        return @record.save && success
      end
    end


    # Call update_record & persist
    def save
      self.update_record
      self.persist
    end


    def save!
      self.save || raise(RecordNotSaved)
    end
  end
end

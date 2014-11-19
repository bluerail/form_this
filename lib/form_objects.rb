module FormObjects
  class Base
    include Virtus.model
    include ActiveModel::Model

    attr_accessor :record


    # Set the model name; used by form_for
    def self.model_name
      name = self.name.sub(/Form$/, '')
      ::ActiveModel::Name.new self, nil, name
    end


    # Define a property
    def self.property name, opts={}, &block
      if block
        attribute name, opts[:type] || String
        validates name, opts[:validates] if opts[:validates]

        #define_method("nested_#{name}") do
        #  block.call
        #  raise
        #end
      else
        attribute name, opts[:type] || String
        validates name, opts[:validates] if opts[:validates]
      end
    end


    def address_attributes= params
      self.address.validate params
    end


    def initialize record
      @record = record
      attrs = {}
      self.attributes.each { |k, v| attrs[k] = @record.send k }
      super attrs

      return self
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
    def validate params
      params.each { |k, v| self.send "#{k}=", v }
      return self.valid?
    end


    # Save record & all dependent records
    def save
      attrs = {}
      self.attributes.each do |k, v|
        if v.is_a? BaseForm
          v = Address.new v.attributes
        end
        attrs[k] = v
      end
      @record.update attrs
      return @record.save
    end


    def save!
      self.save || raise(RecordNotSaved)
    end
  end
end

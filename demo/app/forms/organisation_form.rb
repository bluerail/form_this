class OrganisationForm_Address < FormThis::Base
  model 'Address'
  property :street, validates: { presence: true }
  property :number, validates: { presence: true }
end

class OrganisationForm_Person < FormThis::Base
  model 'Person'
  property :name, validates: { presence: true }
  property :birthdate, type: Date, validates: { presence: true }
end

class OrganisationForm < FormThis::Base
  property :name, validates: { presence: true }
  property :active
  property :address, type: OrganisationForm_Address
  property :people, type: Array[OrganisationForm_Person]


  def set_defaults
    @record.address = Address.new if @record.address.blank?
    if @record.people.blank?
      @record.people.build
      @record.people.build
    end
  end
end

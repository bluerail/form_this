class Organisation < ActiveRecord::Base
  has_one :address
  has_many :people
end

class Address < ActiveRecord::Base
  belongs_to :person
  belongs_to :organisation


  def to_s
    "#{id}: #{street} #{number}"
  end
end

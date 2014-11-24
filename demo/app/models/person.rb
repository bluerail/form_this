class Person < ActiveRecord::Base
  has_one :address

  def to_s
    "#{id}: #{name} (#{birthdate})"
  end
end

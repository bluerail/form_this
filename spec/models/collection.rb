# == Schema Information
#
# Table name: collections
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime
#  updated_at :datetime
#

class Collection < ActiveRecord::Base
  has_many :albums
end

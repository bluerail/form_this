# == Schema Information
#
# Table name: artists
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime
#  updated_at :datetime
#

class Artist < ActiveRecord::Base
  has_many :albums
  has_many :tracks, through: :albums


  def to_s
    name
  end
end

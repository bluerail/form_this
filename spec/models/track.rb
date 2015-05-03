# == Schema Information
#
# Table name: tracks
#
#  id         :integer          not null, primary key
#  name       :string
#  trackno    :integer
#  album_id   :integer
#  created_at :datetime
#  updated_at :datetime
#

class Track < ActiveRecord::Base
  belongs_to :album
  has_one :artist, through: :album
end

class Artist < ActiveRecord::Base
  has_many :albums
  has_many :tracks, through: :albums


  def to_s
    name
  end
end

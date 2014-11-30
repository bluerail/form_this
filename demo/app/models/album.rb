class Album < ActiveRecord::Base
  belongs_to :artist
  has_many :tracks
  belongs_to :genre


  def to_s
    "#{artist.name} − #{name}"
  end
end

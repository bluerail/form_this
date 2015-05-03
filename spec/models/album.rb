# == Schema Information
#
# Table name: albums
#
#  id            :integer          not null, primary key
#  name          :string
#  release_date  :date
#  rating        :integer
#  release_type  :integer
#  genre_id      :integer
#  artist_id     :integer
#  collection_id :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class Album < ActiveRecord::Base
  belongs_to :artist
  belongs_to :collection
  belongs_to :genre
  has_one :comment
  has_many :tracks

  enum release_type: [:album, :soundtrack, :ep, :anthology, :compilation, :live, :demo]


  def to_s
    "#{artist.name} − #{name}"
  end


  def new_genre; genre end
  def new_genre= v; genre = v end
end

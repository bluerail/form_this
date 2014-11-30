class AlbumForm < FormThis::Base
  property :name, validates: { presence: true }
  property :genre, type: Genre
  property :rating, type: Integer, validates: { numericality: { allow_blank: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 } }
  property :release_date, type: Date
  property :tracks, type: Array[TrackForm]
end

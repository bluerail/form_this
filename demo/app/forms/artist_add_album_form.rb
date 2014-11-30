class ArtistAddAlbumForm < FormThis::Base
  model 'artist'
  property :albums, type: Array[AlbumForm]
end

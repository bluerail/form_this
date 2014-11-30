#class ArtistForm_Track < TrackForm; end
#class ArtistForm_Album < AlbumForm; end


class ArtistForm < FormThis::Base
  property :name, validates: { presence: true }
  property :albums, type: Array[AlbumForm]


  def set_defaults
    if @record.albums.blank?
      @record.albums.build
      (1..2).each { |i| @record.albums.first.tracks.build trackno: i }
    end
  end
end

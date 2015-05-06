class ArtistForm < BaseForm
  property :name, validates: { presence: true }
  
  # Allow us to assign an Array of AlbumForms
  property :albums, type: Array[AlbumForm], allow_destroy: true

  def set_defaults
    # If there are no albums yet we build one, so that it's displayed on the
    # form
    @record.albums.build if @record.albums.blank?
  end
end

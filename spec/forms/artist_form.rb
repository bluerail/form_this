class ArtistForm < BaseForm
  property :name, validates: { presence: true }
  
  # Allow us to assign an Array of AlbumForms
  property :albums, type: Array[AlbumForm]

  def set_defaults
    # If there are no albums yet we build one, so that it's displayed on the
    # form
    if @record.albums.blank?
      @record.albums.build
    end
  end


  def persist!
    @record.transaction do
      v = true
      self.albums.each do |a|
        a.record.artist = self.record
        v = v && a.save
      end
      next v && @record.save
    end
  end
end

require 'spec_helper'

describe FormThis do
  describe 'has_many_forms' do
    it 'sets the parent for the nested forms' do
      artist_form = ArtistForm.new Artist.new(name: 'Artist')
      artist_form.validate({
        albums_attributes: {
          '0' => {
            name: 'Album 1',
            release_type: 'album',
          },
          '1' => {
            name: 'Album 2',
            release_type: 'album',
          },
        }
      })

      expect(artist_form.albums[0].parent).to eq(artist_form)
      expect(artist_form.albums[1].parent).to eq(artist_form)
    end


    it 'persist the nested forms' do
      artist_form = ArtistForm.new Artist.new(name: 'Artist')
      artist_form.validate({
        albums_attributes: {
          '0' => {
            name: 'Album 1',
            release_type: 'album',
          },
          '1' => {
            name: 'Album 2',
            release_type: 'album',
          },
        }
      })

      c = Album.count
      expect(artist_form.save).to eq(true)
      expect(Album.count).to eq(c + 2)
      expect(Album.last.id).to eq(artist_form.albums.last.id)
      expect(Album.last.name).to eq('Album 2')
    end
  end
end

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


    it 'allows updating' do
      next
      artist = create :artist, albums: [create(:album), create(:album)]
      artist_form = ArtistForm.new artist
      album_id = artist_form.albums[1].id
      artist_form.validate({
        albums_attributes: {
          '0' => { },
          '1' => { name: 'New album name' },
        }
      })

      expect(artist_form).to be_valid
      expect(artist_form.save).to eq(true)
      expect(Album.find(album_id).name).to eq('New album name')
    end


    it 'allows destroying' do
      artist = create :artist, albums: [create(:album), create(:album)]
      artist_form = ArtistForm.new artist
      album = artist_form.albums[1]
      artist_form.validate({
        albums_attributes: {
          '0' => { },
          '1' => { _destroy: true },
        }
      })

      expect(artist_form).to be_valid
      expect {
        expect(artist_form.save).to eq(true)
      }.to change(Album, :count).by(-1)
      expect(album.record).to be_destroyed
      expect(Artist.find(artist_form.id).albums.length).to eq(1)
    end
  end
end

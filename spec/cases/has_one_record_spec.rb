require 'spec_helper'

describe FormThis do
  describe 'has_one_record' do
    it 'allows assigning an AR' do
      genre = Genre.create name: 'Prog rock'

      album_form = AlbumForm.new Album.new
      expect(album_form.genre).to eq(nil)

      album_form.genre = genre
      expect(album_form.genre.class).to eq(Genre)
      expect(album_form.genre).to eq(genre)
      expect(album_form.genre.id).to eq(genre.id)

      # Make sure we didn't update the record
      expect(album_form.record.genre).to eq(nil)
    end


    it 'gets the record from an id' do
      genre = Genre.create name: 'Prog rock'

      album_form = AlbumForm.new Album.new
      expect(album_form.genre).to eq(nil)

      album_form.genre = genre.id
      expect(album_form.genre.class).to eq(Genre)
      expect(album_form.genre).to eq(genre)
      expect(album_form.genre.id).to eq(genre.id)

      # Make sure we didn't update the record
      expect(album_form.record.genre).to eq(nil)
    end


    it 'allows setting the record to nil' do
      album_form = AlbumForm.new Album.new
      album_form.genre = Genre.new
      expect(album_form.genre.class).to eq(Genre)

      album_form.genre = nil
      expect(album_form.genre).to eq(nil)

      album_form.genre = ''
      expect(album_form.genre).to eq(nil)
    end


    it "raises when it can't find the record" do
      album_form = AlbumForm.new Album.new
      expect { album_form.genre = 99999 }.to raise_error(ActiveRecord::RecordNotFound)
    end


    it "raises on unexpected input" do
      album_form = AlbumForm.new Album.new
      expect { album_form.genre = 'str' }.to raise_error(TypeError)
      expect { album_form.genre = :sym }.to raise_error(TypeError)
      expect { album_form.genre = [] }.to raise_error(TypeError)
    end


    it 'loads the field from the record' do
      genre = Genre.create name: 'Prog rock'
      album = Album.new name: 'Into the Electric castle', genre: genre

      album_form = AlbumForm.new album
      expect(album_form.genre).to eq(genre)
    end
  end
end

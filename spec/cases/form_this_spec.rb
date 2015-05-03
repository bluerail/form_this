require 'spec_helper'

describe FormThis do
  describe 'execute_for_all_forms' do
    it 'is run once for every form, including self' do
      artist_form = ArtistForm.new build(:artist)
      artist_form.albums << AlbumForm.new(build(:album))

      result = []
      artist_form.execute_for_all_forms(true) { |form, name| result << form.hash }
      expect(result.sort).to eq([
        artist_form.hash, artist_form.albums[0].hash,
        artist_form.albums[1].hash, artist_form.albums[0].comment.hash,
        artist_form.albums[1].comment.hash
      ].sort)
    end


    it 'is run once for every form, excluding self' do
      artist_form = ArtistForm.new build(:artist)
      artist_form.albums << AlbumForm.new(build(:album))
      result = []
      artist_form.execute_for_all_forms(false) { |form, name| result << form.hash }
      expect(result.sort).to eq([
        artist_form.albums[0].hash, artist_form.albums[1].hash,
        artist_form.albums[0].comment.hash, artist_form.albums[1].comment.hash
      ].sort)
    end


    it 'sets the correct relation name' do
      # TODO
    end
  end
end

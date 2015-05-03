require 'spec_helper'

describe FormThis do
  describe 'has_many_records' do
    it 'allows assigning an AR' do
      album_form = AlbumForm.new Album.new

      expect(album_form.tracks).to eq([])

      track1 = build :track
      track2 = build :track

      album_form.tracks << track1
      album_form.tracks << track2

      expect(album_form.tracks[0]).to eq(track1)
      expect(album_form.tracks[1]).to eq(track2)

      expect(album_form.tracks[0]).to eq(track1)
      expect(album_form.tracks[1]).to eq(track2)

      expect(album_form.tracks[0].id).to eq(track1.id)
      expect(album_form.tracks[1].id).to eq(track2.id)

      # Make sure we didn't update the record
      expect(album_form.record.tracks).to eq([])
    end
  end
end

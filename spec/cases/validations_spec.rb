require 'spec_helper'

describe FormThis do
  describe 'validations' do
    it 'sets errors' do
      artist_form = ArtistForm.new Artist.new
      expect(artist_form.valid?).to eq(false)
      expect(artist_form.errors[:name]).to be_present
    end


    it 'sets errors for nested forms' do
      artist_form = ArtistForm.new Artist.new
      expect(artist_form.valid?).to eq(false)
      expect(artist_form.albums.first.errors[:name]).to be_present
    end


    it "doesn't allow saving when not valid" do
      artist_form = ArtistForm.new Artist.new
      expect {
        expect(artist_form.save).to eq(false)
      }.to_not change(Artist, :count)
    end


    it "doesn't allow saving when a nested form is invalid" do
      artist_form = ArtistForm.new Artist.new(name: 'Hello')
      expect {
        expect(artist_form.save).to eq(false)
      }.to_not change(Artist, :count)
    end
  end
end

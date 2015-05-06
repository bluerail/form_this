require 'spec_helper'

describe FormThis do
  describe 'has_one_form' do
    it 'sets the parent for the nested form' do
      album_form = AlbumForm.new Album.new
      album_form.validate({
        comment_attributes: {
          text: 'Heya'
        }
      })

      expect(album_form.comment).to be_valid
      expect(album_form.comment.parent).to eq(album_form)
    end


    it 'persist the nested form' do
      album_form = AlbumForm.new build(:album)
      album_form.validate({
        comment_attributes: {
          text: 'Heya'
        }
      })

      expect(album_form.save).to eq(true)
      expect(Comment.last.id).to eq(album_form.comment.id)
      expect(Comment.last.text).to eq('Heya')
    end


    # TODO: This case requires quite a bit of mucking about in the persist!
    # method, and could be made easier (like reject_if or some such).
    #
    # Maybe:
    #
    #     property :comment, type: CommentForm, build: true, reject_if: :blank_attributes
    #
    # To build one by default, and then reject if the attributes are all blank
    # (otherwise, run validate and possibly save, if valid).
    it "doesn't save anything if it's optional" do
      album_form = AlbumForm.new build(:album)

      c = Comment.count
      expect(album_form.save).to eq(true)
      expect(Comment.count).to eq(c)
    end


    it 'cannot be destroyed if not allowed' do
      #album_form = AlbumForm.new create(:album)
      # TODO
      #album_form.validate({
      #  comment_attributes: {
      #    _destroy: true,
      #  }
      #})
    end


    it 'can be destroyed if allowed' do
      album_form = AlbumForm.new create(:album)
      album_form.validate({
        comment_attributes: {
          _destroy: true,
        }
      })

      expect {
        album_form.save
      }.to change(Comment, :count).by(-1)
    end
  end
end

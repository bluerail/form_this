class AlbumForm < BaseForm
  # Default type is string
  property :name, validates: { presence: true }

  # The type is an ActiveRecord class, this means we can either assign an AR
  # instance, or an Integer which we will use to find the AR.
  property :genre, type: Genre

  # Integer
  property :rating, type: Integer, validates: { numericality: { allow_blank: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 } }

  # Date
  property :release_date, type: Date

  # This is an enum
  property :release_type, validates: { inclusion: { in: Album.release_types } }

  # Allow us to assign an Array of TrackForms
  property :tracks, type: Array[TrackForm]

  # I can't think of a good relation :-( Use this for tests until I do
  # property :comment, type: CommentForm, build: true, reject_if: :blank_attributes
  property :comment, type: CommentForm, reject_if: -> (attr) { attr.all? { |k, v| k.to_s == '_destroy' || v.blank? } }, allow_destroy: true


  def set_defaults
    @record.comment = Comment.new if @record.comment.blank?
  end


  def persist!
    @record.transaction do
      v = true

      if !self.comment.attributes.all? { |k, v| k.to_s == '_destroy' || v.blank? }
        v = v && self.comment.save
      elsif self.comment._destroy
        self.comment.record.destroy
      else
        @record.comment = nil
      end

      v = v && @record.save

      next v
    end
  end
end

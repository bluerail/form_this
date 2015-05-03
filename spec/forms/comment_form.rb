class CommentForm < BaseForm
  property :text, validates: { presence: true }
  property :_destroy, type: Boolean
end

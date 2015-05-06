class CommentForm < BaseForm
  property :text, validates: { presence: true }
end

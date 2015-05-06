class GenreForm < BaseForm
  property :name, validates: { presence: true }
end

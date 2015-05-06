class CollectionForm < BaseForm
  property :name, validates: { presence: true }
end


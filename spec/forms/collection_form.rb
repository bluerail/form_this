class CollectionForm < FormThis::Base
  # TODO: validate unique
  property :name, validates: { presence: true }
end


class TrackForm < FormThis::Base
  # Default type is string
  property :name, validates: { presence: true }

  property :trackno, type: Integer
end

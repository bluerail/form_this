class TrackForm < FormThis::Base
  property :name, validates: { presence: true }
  property :trackno, type: Integer
end

class TrackForm < BaseForm
  property :name, validates: { presence: true }
  property :trackno, type: Integer
end

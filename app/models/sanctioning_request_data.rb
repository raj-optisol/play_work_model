class SanctioningRequestData < BaseModel::Data
  include Symbolize::ActiveRecord
  include Notable::Data
  property :kind, type: :symbol, default: :club
  property :status, type: :symbol, default: :pending
  property :payload

  property :order_id

  symbolize :kind, in: [:club, :academy, :league, :tournament]
  symbolize :status, in: [:pending, :approved, :pending_payment, :denied, :inactive]

  has_n(:notes).to(NoteData)
  has_n(:contacts).to(UserData)
  has_one(:issuer)
  has_one(:target)
  has_one(:on_behalf_of)
end

class CompetitionEntryData < BaseModel::Data
  include Symbolize::ActiveRecord
  include Notable::Data
  property :kind, type: :symbol, default: :request
  property :status, type: :symbol, default: :pending
  property :payload

  property :order_id

  symbolize :kind, in: [:request, :invite]
  # symbolize :status, in: [:pending, :pending_payment, :requestor_response_required, :requestor_response_received, :approved, :denied, :refunded, :inactive ]
  symbolize :status, in: [:pending, :approved, :denied, :inactive ]
  
  has_n(:notes).to(NoteData)

  has_one(:competition).to(CompetitionData)
  has_one(:division).to(DivisionData)
  has_one(:team).to(TeamData)
  has_one(:roster).to(RosterData)      

  has_one(:issuer)
  has_one(:target).to(DivisionData)
  has_one(:on_behalf_of).from(RosterData, :play_request)
  
end

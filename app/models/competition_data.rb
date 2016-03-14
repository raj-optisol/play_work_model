class CompetitionData < BaseModel::Data
  include Staffable::Data
  include Locatable::Data
  include Symbolize::ActiveRecord
  include Avatarable::Data
  COMPETITION_KINDS = [ :league, :tournament, :camp]
  has_avatar default: 'default_organization_avatar_i68wap'

  has_n(:staff).from(:staff_for)
  has_n(:divisions).to(DivisionData)
  has_n(:sanctioning_requests).from(:on_behalf_of)
  has_n(:sanctioning_bodies).from(:sanctions)

  has_one(:sb_region)
  has_one(:sb_rep).from(:rep_for)
  #TODO: Remove this once data migration is run
  has_one(:organization).from(OrganizationData, :competitions)

  has_n(:locations)

  has_n(:entries).from(CompetitionEntryData, :competition)
  has_n(:cards).from(CardData, :processor)

  property :name
  property :migrated_id

  property :start_date, type: Fixnum
  property :end_date, type: Fixnum
  property :registration_deadline, type: Fixnum
  property :kind, default: COMPETITION_KINDS.first, type: :symbol
  property :level, default: :youth_rec, type: :symbol
  property :game_roster_size, type: Fixnum
  property :team_roster_size, type: Fixnum
  property :open, default: true
  property :url

  property :phone_number
  property :fax_number
  property :email

  property :can_process_cards  # delete after migration

  symbolize :level, in: [:youth_competitive, :youth_rec, :adult_competitive, :adult_rec]
  symbolize :kind, in: COMPETITION_KINDS
  # has_many :account_transactions, class_name: "AccountTransactionData", foreign_key: "payment_account_id"

  def viewable_by?(user, rels=[])
    true
  end
end

require 'symbolize'

class CardData < BaseModel::Data
  include Symbolize::ActiveRecord
  include Notable::Data
  include Documentable::Data

  %w(first_name middle_name last_name).each {|attr| property attr}

  property :birthdate, :type => Date
  property :created_at, type: Fixnum
  property :expires_on, type: Fixnum
  property :processed_on, type: Fixnum
  property :approved_on, type: Fixnum
  property :inactive_on, type: Fixnum
  property :status, default: :new
  property :message_status, default: :read
  property :kind
  property :order_id
  property :order_item_id
  property :amount_paid, type: Float
  property :duplicate_lookup_hash
  property :has_duplicates, default: false
  property :is_renewal, default: false
  property :approval_email_sent, default: false, type: :boolean

  has_one(:carded_user).to(UserData)
  has_one(:carded_for).to(BaseModel::Data)
  has_one(:sanctioning_body).to(SanctioningBodyData)

  has_n(:notes).to(NoteData)
  has_n(:documents).from(DocumentData, :cards)

  has_one(:processor).to(BaseModel::Data)

  symbolize :status, in: [
    :new_and_approved,
    :new,
    :processed,
    :approved,
    :denied,
    :dual_card,
    :refunded,
    :expired,
    :inactive,
    :released
  ]
  symbolize :message_status, in: [
    :read,
    :requestor_response_required,
    :requestor_response_received
  ]
  symbolize :kind, in: [:player, :staff]


  def add_document(doc)
    self.documents << doc._data
    doc._data
  end

  def set_duplicate_lookup_hash
    return unless self && self.first_name && self.last_name

    lookup_keys = [self.first_name.downcase]
    lookup_keys << self.last_name.downcase
    # Birthdate must be in the format yyyy-mm-dd.
    lookup_keys << self.birthdate.strftime('%Y-%m-%d') if self.birthdate

    self.duplicate_lookup_hash = Digest::MD5.hexdigest(lookup_keys.join)
  end
end

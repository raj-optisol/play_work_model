# encoding: UTF-8
# Class representing Sanctioning Body card
class Card
  include Edr::Model
  include BaseModel::Model
  include Notable::Model

  # USCS mandated default expiration month and year.
  EXP_MONTH = 8
  EXP_DAY = 1
  # Expiration window in terms of months.
  # This indicates how many months earlier a user can request a card.
  EXP_WINDOW = 1

  def_delegators(
    :_data,
    :sanctioning_body=,
    :carded_user=,
    :carded_for=,
    :add_document,
    :set_duplicate_lookup_hash)

  def add_document(doc)
    wrap _data.add_document(doc)
  end

  wrap_associations(
    :sanctioning_body,
    :carded_user,
    :carded_for,
    :notes,
    :documents,
    :processor
  )

  def full_name
    names = [first_name]
    names << middle_name unless middle_name.blank?
    names << last_name
    names.join(' ')
  end

  def approved?
    [:approved, :dual_card].include?(status)
  end

  def processed?
    [:processed].include?(status)
  end

  def inactive?
    [:expired, :inactive, :refunded, :released].include? status
  end

  def new?
    [:new].include?(status)
  end

  def declined?
    status == :denied
  end

  def renew
    return unless allow_renewal?

    self.status = :approved
    self.message_status = :read
    self.is_renewal = true
    self.approved_on = Time.now
  end

  def reset
    self.status = :new
    self.approved_on = nil
    self.inactive_on = nil
    reset_expiration
    set_duplicate_lookup_hash
  end

  def refresh_duplicates(duplicate_cards)
    self.has_duplicates = duplicate_cards.count > 0
    duplicate_cards.each { |card| card.has_duplicates = true }
  end

  def default_expiration(time = nil)
    now = time ? time : Time.now
    next_season = (now.month / (EXP_MONTH - EXP_WINDOW)).floor
    exp = Time.new(now.year + next_season, EXP_MONTH, EXP_DAY)
    exp += 1.year if kind.to_s =~ /staff/i

    exp
  end

  private

  def reset_expiration
    self.expires_on = default_expiration
  end

  def allow_renewal?
    !has_duplicates && kind.to_s =~ /player/i
  end
end

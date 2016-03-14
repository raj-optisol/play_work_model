class CompetitionEntry
  include Edr::Model
  include BaseModel::Model

  fields :kind, :status, :payload, :order_id
  wrap_associations :competition, :division, :team, :roster
  wrap_associations :notes, :target, :issuer, :on_behalf_of, :contacts
  def_delegators :_data, :issuer=, :competition=, :division=, :team=, :roster=

  def organization
    competition.organization
  end

  def add_note(note)
    wrap _data.add_note(note)
  end

  def create_note(note_attrs)
    wrap _data.create_note(note_attrs)
  end

  def approved?
    self.status == :approved
  end

  def denied?
    self.status == :denied
  end

  def inactive?
    self.status == :inactive
  end

  def pending?
    [:pending, :pending_payment].include?(self.status)
  end

  def needs_payment?
    self.status == :pending_payment
  end
end

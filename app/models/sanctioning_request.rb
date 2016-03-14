class SanctioningRequest
  include Edr::Model
  include BaseModel::Model

  fields :kind, :status, :payload, :order_id

  wrap_associations :notes, :target, :on_behalf_of, :contacts

  def_delegators :_data, :on_behalf_of=, :issuer=, :target=

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

  def pending?
    [:pending, :pending_payment].include?(self.status)
  end

  def needs_payment?
    self.status == :pending_payment
  end

  def issuer
    wrap(_data.issuer)|| Null::User.new
  end
end

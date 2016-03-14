class Sanction
  include Edr::Model
  include BaseRelationship::Model
  include Empowerable::Check

  fields :status
  fields :can_process_cards

  attr_accessor :payment_account

  def sb
    wrap _data.sb
  end

  def sanctioning_body
    wrap _data.sanctioning_body
  end

  def sanctioned_item
    wrap _data.sanctioned_item
  end
end

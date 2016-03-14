class CardProduct
  include Edr::Model

  fields :id, :name, :updated_at, :sanctioning_body_id, :organization_id, :age, :card_type, :amount, :deleted_at
  
end

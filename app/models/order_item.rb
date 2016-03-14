# encoding: UTF-8
class OrderItem
  include Edr::Model

  fields(:id,
         :status,
         :product_for_obj_id,
         :product_for_obj_type,
         :order_id,
         :amount,
         :product_id,
         :product_type,
         :description,
         :competition_id,
         :item_id,
         :item_type
        )
  wrap_associations :order

  def connect_card(card)
    self.item_id = card.kyck_id
    self.item_type =  'Card'
    self.status = :processed unless card.status.to_s =~ /new/i
  end

  def save
    _data.save
  end

  def save!
    _data.save!
  end
end

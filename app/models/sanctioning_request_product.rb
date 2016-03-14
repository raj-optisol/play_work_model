class SanctioningRequestProduct
  include Edr::Model

  fields :id, :updated_at, :sanctioning_body_id, :kind, :amount, :kind, :active

  def has_orders?
    OrderItemData.where(product_id: id, product_type: "SanctioningRequestProduct").any?
  end

end
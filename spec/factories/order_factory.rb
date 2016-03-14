require 'factory_girl'

FactoryGirl.define do

  factory :order, class: OrderData do
    kind :card_request
    status :new
    amount 0.0
  end

end

def create_order(initiator, payer, payee, attrs={})
  o = Order.build(FactoryGirl.attributes_for(:order).merge(attrs))
  o.payer_id = payer.kyck_id
  o.payer_type = payer.class.to_s
  o.payee_id = payee.kyck_id
  o.payee_type = payee.class.to_s
  o.initiator_id = initiator.kyck_id
  o.assigned_kyck_id = initiator.kyck_id
  o.assigned_name = initiator.respond_to?(:full_name) ? initiator.full_name : initiator.name
  OrderRepository.persist! o
end

def order_item_hash
  {
    product_for_obj_id: 'fake-123',
    product_for_obj_type: 'User',
    amount: 15,
    product_id: 0,
    product_type: 'CardProductData',
    description: 'Card for User',
    item_type: 'Card',
    item_id: 'fake-123'
  }
end

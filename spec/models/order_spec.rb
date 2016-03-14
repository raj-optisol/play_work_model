require 'spec_helper'

describe Order do
  
  describe "#add_order_item" do
    
    let(:requestor) { regular_user }
    let(:sb) { create_sanctioning_body }
    let(:org) { create_club }
    let(:order) {
        attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request'}
        ord = Order.build(attrs)
        OrderRepository.persist ord
        ord
    }
    
    let(:srp) {
      attrs = {:kind => 'competition', :amount=>1000.0, :sanctioning_body_id => sb.kyck_id}
      req = SanctioningRequestProduct.build(attrs)
      SanctioningRequestProductRepository.persist req
    }
    
    it 'should increase order items count by 1' do
        # oi = OrderItem.build(:amount=>srp.amount, :product_id =>srp.id, :product_type =>srp.class.to_s, :order_id => order.id)
        # OrderRepository::OrderItemRepository.persist oi
        order.add_order_item(:amount=>srp.amount, :product_id =>srp.id, :product_type =>srp.class.to_s)
        OrderRepository.persist order
        order.order_items.count.should == 1
        # @order.add_order_item(:product_for_obj_id=> (@for_obj ? @for_obj.kyck_id : 0), :product_for_obj_type=> (@for_obj ? @for_obj.class.to_s : ''), :amount=>@product.amount, :product_id => @product.id, :product_type =>@product.class.to_s, :description => input['description'])        
        
    end
    
  end
end

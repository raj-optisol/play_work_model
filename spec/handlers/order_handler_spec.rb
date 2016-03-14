require 'spec_helper'

describe OrderHandler do

  describe "Update SanctioningRequest Status" do
    let(:requestor) { regular_user }
    let(:sb) { create_sanctioning_body }
    let(:org) { create_club }
    let(:order) {
      create_order(requestor, org, sb, {kind: :sanctioning_request, amount: 1000.0})
    }
    let!(:sanctioning_request) { create_sanctioning_request(sb, org, requestor)}


    subject { OrderHandler.new }

    before(:each) do
      add_user_to_org(requestor, org, {title: "registrar", permission_sets: [PermissionSet::MANAGE_STAFF]}, UserRepository)
      @product = SanctioningRequestProduct.build({:kind => 'club', :amount=>1000.0, :sanctioning_body_id => sb.kyck_id})
      SanctioningRequestProductRepository.persist @product
    end

    it "sets sanctioning_request order_id and status to pending_payment " do

      res = subject.sanctioning_request_created(sanctioning_request, org, sb)
      sr = SanctioningRequestRepository.find(sanctioning_request.id)
      sr.status.should == :pending_payment
      sr.order_id.should_not be_nil
    end

    it "creates order and order_item " do

      res = subject.sanctioning_request_created(sanctioning_request, org, sb)
      sr = SanctioningRequestRepository.find(sanctioning_request.id)
      o = OrderRepository.find(sr.order_id)
      o.should_not be_nil
      o.order_items.count.should == 1
      o.order_items.first.product_id.should == @product.id
      o.order_items.first.product_for_obj_id.to_s.should == sr.kyck_id
    end

  end
end

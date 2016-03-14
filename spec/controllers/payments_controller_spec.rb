require 'spec_helper'

describe PaymentsController do
  include Devise::TestHelpers
  let(:requestor) {regular_user}
  before do
    sign_in_user(requestor)
  end

  describe "#create" do

    let(:order) {
      o = FactoryGirl.create(:order)
      OrderRepository.find(o.id)
    }


    context "when an order is paid" do
      before do
        stub_wisper_publisher("KyckRegistrar::Actions::MakePayment", :execute, :order_paid, order)
        order.add_order_item(product_id: 1234, product_type:'CardProduct', product_for_obj_id: '1234', product_for_obj_type: 'User')
        OrderRepository.persist(order)
      end

      it "publishes the order to that will create the cards" do

        renewer = double
        CardRenewer.stub(:new) { renewer }
        renewer.stub(:run)

        processor = stub_const("Rabbitmq", Class.new)
        processor.should_receive(:publish).with({name:'order_paid', content:{order_id: order.id, user_id: requestor.kyck_id}}.to_json, 'order.paid')

        post :create, order_id: order.id
      end
    end
    context "when there is a payment error" do

      before do
        stub_wisper_publisher("KyckRegistrar::Actions::MakePayment", :execute, :payment_error, KyckRegistrar::OrderAlreadyPaidError.new)
      end
      subject{
        post :create, order_id: order.id
      }

      it "sets the flash message"  do
        subject
        flash[:error].should =~ /already/i
      end

      it "redirects to new" do
        subject
        response.should redirect_to new_order_payments_path(order)
      end
    end
  end
end

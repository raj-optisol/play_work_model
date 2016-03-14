require 'spec_helper'

describe OrdersController do

  let(:requestor ) {regular_user}
  before do
    sign_in_user(requestor)
  end
  describe "#refund" do
    
    context "when the user has permission" do
        let(:issuer) {regular_user}
        let(:payer) {create_club}
        let(:payee) {create_sanctioning_body}

        let!(:order) { create_order(issuer, payer, payee, status: :submitted, payment_status: :authorized)}
    
      context "and the order is in a submitted stat" do
        before  do
          add_user_to_org(requestor, payee, permission_sets: [PermissionSet::MANAGE_MONEY])
        end

        it "calls the refund order transaction" do
          m = mock_execute_action(KyckRegistrar::Actions::RefundOrder, nil, true)          
          m.stub(:on)
          post :refund, id: order.id
        end
      
      end
    
    end
  end
end

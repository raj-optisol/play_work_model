# encoding: UTF-8
require 'spec_helper'
module Organizations
  describe CardsController do
    let(:club) { create_club }
    let(:requestor) { regular_user }
    before(:each) do
      sign_in_user(requestor)
    end
    describe "#index" do
      context "for an organization" do
        it "creates the order" do
          mock_execute_action(
            KyckRegistrar::Actions::GetOrCreateOrder,
            { payer_id: club.kyck_id,
              payer_type: 'Organization' },
              Order.new)
          get :index, organization_id: club.kyck_id
        end
      end
    end
  end
end

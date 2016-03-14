require 'spec_helper'

describe OrderItemsController do
  include Devise::TestHelpers

  let(:requestor) {regular_user}
  let(:club) {create_club}
  let(:uscs) {create_sanctioning_body}
  let(:order) {create_order(requestor, club, uscs)}
  let(:cp) {create_card_product(uscs)}

  before do
    sign_in_user(requestor)
  end

  describe "#index" do

    let(:user1) { regular_user }
    let(:user2) { regular_user }
    let!(:cr_item1) {
      order.add_order_item(
        product_for_obj_id: user1.kyck_id,
        product_for_obj_type: 'User',
        amount: 15,
        product_id: cp.id,
        product_type: 'CardProductData',
        description: "Card for User"
      )
    }
    let!(:cr_item2) {
      order.add_order_item(
        product_for_obj_id: user2.kyck_id,
        product_for_obj_type: 'User',
        amount: 15,
        product_id: cp.id,
        product_type: 'CardProductData',
        description: "Card for User"
      )
    }

    context "when team filters are provided" do
      before do
        UserRepository.stub(:get_users_for_team).with(anything, anything) { [user1] }
      end

      it "filters the results" do
        get :index, order_id: order.id,  filter: {team_id: 'whatever'}, format: :json
        json.count.should == 1
      end
    end
  end
end

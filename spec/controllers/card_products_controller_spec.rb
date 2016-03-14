require 'spec_helper'

describe CardProductsController do
  include Devise::TestHelpers

  let(:requestor) {regular_user}
  let(:uscs) {create_sanctioning_body(name: 'USCS')}
  let(:card_product) {create_card_product(uscs)}

  before do
    sign_in_user(requestor)   
  end

  describe "#index" do
    it "calls the right action" do
      mock_execute_action(KyckRegistrar::Actions::GetCardProducts, {conditions: {:order=>["updated_at asc"], :limit=>25, :offset=>0}}, [card_product])
      get :index, format: :json, sanctioning_body_id: uscs.kyck_id
      json[0]["id"] == card_product.id
    end
  end

  describe "#destroy" do
    it "calls the right action" do
      mock_execute_action(KyckRegistrar::Actions::DeleteCardProduct, {id: card_product.id}, true)
      delete :destroy, sanctioning_body_id: uscs.kyck_id, id: card_product.id
    end
    
  end
end

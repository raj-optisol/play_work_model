require 'spec_helper'

describe LocationsController do
  include Devise::TestHelpers
  let(:requestor) {regular_user}
  let(:club) {create_club}

  before do
    sign_in_user(requestor)
  end

  describe "#create" do

    let(:location_attributes) {
      {
        "name"=> 'Location',
        "address1"=> '123 Main Street',
        "address2"=> 'Suite 500',
        "city"=> 'Charlotte',
        "state"=> 'NC',
        "zipcode"=> '28282',
        "country"=> 'USA'
      }
    }
      before do
      stub_wisper_publisher("KyckRegistrar::Actions::CreateLocation", :execute, :location_created, Location.build)
      end

    it "calls the right action" do
      post :create, organization_id: club.kyck_id, location: location_attributes, format: :json
    end
  end
end

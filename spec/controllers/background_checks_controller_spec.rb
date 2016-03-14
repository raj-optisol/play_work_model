require 'spec_helper'

describe BackgroundChecksController do
  include Devise::TestHelpers

  before(:each) do
    @account = FactoryGirl.create(:account)
    @user = regular_user({kyck_id: @account.kyck_id.to_s})
    sign_in(@account)
  end

  context "PUT update" do
    
    context "when valid data is provided" do
      let(:staff) { regular_user }
      let(:org) { create_club }
      let(:background_check_attrs) { {data: "1234567" } }

      before(:each) do
        add_user_to_org(@user, org,{title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
        add_user_to_org(staff, org,{title: "Test"})        
      end

      it "renders a success message on successfull update" do
        stub_wisper_publisher("KyckRegistrar::Actions::StaffBackgroundCheck", :execute, :background_check_updated, staff )
        put :update, organization_id: org.kyck_id,  id: staff.kyck_id, background_check: background_check_attrs, format: :json
        body = JSON.parse(response.body)
        expect(body["success"]).to eq(true)
      end
    
      it "renders a failure message on failure" do
        stub_wisper_publisher("KyckRegistrar::Actions::StaffBackgroundCheck", :execute, :background_check_failed, staff)
        put :update, organization_id: org.kyck_id,  id: staff.kyck_id, background_check: background_check_attrs, format: :json
        body = JSON.parse(response.body)
        expect(body["failure"]).to eq(false)
      end
    end
  end

  context "DELETE 'destroy'" do

      let(:staff) { regular_user }
      let(:org) { create_club }

      before(:each) do
        add_user_to_org(@user, org,{title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
        add_user_to_org(staff, org,{title: "Test"})        
        staff.background_check = "123456"
        UserRepository.persist staff
      end

      it "removes the background check" do
        delete :destroy, organization_id: org.kyck_id,  id: staff.kyck_id, format: :json
        user = UserRepository.find(kyck_id: staff.kyck_id)
        expect(user.background_check).to eq(nil)
      end
  end
end

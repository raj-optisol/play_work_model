require 'spec_helper'

describe OrganizationsController do
  include Devise::TestHelpers

  let(:requestor) { regular_user }
  before(:each) do
    sign_in_user(requestor)
  end

  describe "#new" do

    context "when a user is logged in" do

      it "assigns a new organization variable" do
        get :new
        expect(assigns(:org)).to_not be_nil
      end
    end
  end

  describe "#create" do
    context "for organizations" do
      context "when the params are valid" do
        let(:org) { create_club }
        let(:attrs) { {name: 'Org', kind: 'club'} }

        before do
          stub_wisper_publisher("KyckRegistrar::Actions::CreateOrganization", :execute, :organization_created, org)
        end

        it "redirects to the organizations " do
          post :create, organization: attrs 
          response.should redirect_to organization_path(org.kyck_id)
        end

        context "when format is json" do
          it "returns the organization" do
            post :create, organization: attrs , format: :json
            assert_not_nil json['name']
          end

          context "and the org is invalid" do
            before do
              org.stub(:errors) { { "email" => ["has been taken" ] } }
              stub_wisper_publisher("KyckRegistrar::Actions::CreateOrganization", :execute, :invalid_organization, org)
            end

            it "returns errors " do
              post :create, organization:attrs, format: :json
              assert_not_nil json['errors']
            end

            it "returns the right status" do
              post :create, organization: attrs, format: :json
              assert_equal 422, response.status
            end
          end
        end
      end

      context "when invalid organzation params are supplied" do
        let(:org) {
          o = Organization.new
          o.valid?
          o
        }
        before do
          stub_wisper_publisher("KyckRegistrar::Actions::CreateOrganization", :execute, :invalid_organization, org)
        end

        it "redirects to the new action" do
          post :create, organization: {kind: "club"}
          response.should redirect_to new_organization_path
        end

        it "assigns org" do
          post :create, organization: {kind: "club"}
          assigns(:org).should_not be_nil
        end

      end
    end

    context "for competitions" do
      context "when the params are valid" do
        let(:comp) { create_competition }
        let(:attrs) { {name: 'Comp', kind: 'tournament'} }

        before do
          stub_wisper_publisher("KyckRegistrar::Actions::CreateCompetition", :execute, :competition_created, comp)
        end

        it "redirects to the competitions " do
          post :create, organization: attrs 
          response.should redirect_to competition_path(comp.kyck_id)
        end

        context "when format is json" do
          it "returns the organization" do
            post :create, organization: attrs , format: :json
            assert_not_nil json['name']
          end

          context "and the comp is invalid" do
            before do
              comp.stub(:errors) { { "email" => ["has been taken" ] } }
              stub_wisper_publisher("KyckRegistrar::Actions::CreateCompetition", :execute, :invalid_competition, comp)
            end

            it "returns errors " do
              post :create, organization:attrs, format: :json
              assert_not_nil json['errors']
            end

            it "returns the right status" do
              post :create, organization: attrs, format: :json
              assert_equal 422, response.status
            end
          end
        end
      end
    end
  end

  describe "#edit" do
    let(:org) {create_club}

    context "when a user has permission" do
      it "calls the action" do
        mock_execute_action(KyckRegistrar::Actions::GetOrganizations, {conditions: {kyck_id: org.kyck_id}, permission_sets: [PermissionSet::MANAGE_ORGANIZATION]}, [org] )
        get :edit, id: org.kyck_id
      end

      it "assigns the organization" do
        stub_execute_action(KyckRegistrar::Actions::GetOrganizations, nil, [org] )
        get :edit, id: org.kyck_id
        assigns(:org).should be_a(Organization)
        assigns(:org).id.should == org.kyck_id
      end
    end

    context "when the user does not have permission" do
      it "404s" do
        stub_execute_action(KyckRegistrar::Actions::GetOrganizations, nil, nil, KyckRegistrar::PermissionsError)

       get :edit, id: org.kyck_id
       response.status.should == 404
      end
    end
  end

  describe "#index" do
    describe "when permissions are supplied" do

      before(:each)  do
        @account = FactoryGirl.create(:account)
        @user = regular_user({kyck_id: @account.kyck_id.to_s})

        @org = create_club
        @org.add_staff(@user, {title: 'Dood',permissons_set:  [PermissionSet::MANAGE_STAFF]})
        OrganizationRepository.persist @org

        create_club

        sign_in(@account)
      end

      it "calls the action with the right parameters" do
        @org.permissions =  [PermissionSet::MANAGE_STAFF]
        mock_execute_action(KyckRegistrar::Actions::GetOrganizations, {order: "updated_at", order_dir:'asc', limit: 25, offset: 0, conditions: {}}, [@org])
        get :index, format: :json, ps: PermissionSet::MANAGE_STAFF, orderby: "updated_at", dir: "asc"
        json.count.should == 1
        json[0]["id"].should == @org.id.to_s
      end

      context "for a user" do
        let(:other_user) {regular_user}
        before do
          add_user_to_org(other_user, @org)
        end

        it "calls the action with the right parameters" do

          mock_execute_action(KyckRegistrar::Actions::GetOrganizations, {user_id: other_user.kyck_id, order: "updated_at", order_dir:'asc', limit: 25, offset: 0, conditions: {}}, [@org])

          get :index, format: :json, ps: PermissionSet::MANAGE_STAFF, user_id: other_user.kyck_id, orderby: "updated_at", dir: "asc"
          json.count.should == 1
          json[0]["id"].should == @org.id.to_s

        end

      end
    end

    describe "for a sanctioning body" do
      let(:sanctioning_body) {create_sanctioning_body}
      let(:org) {create_club}
      before(:each)  do
        @account = FactoryGirl.create(:account)
        @user = regular_user({kyck_id: @account.kyck_id.to_s})
        @org = create_club
        sanctioning_body.add_staff(@user, {title: 'Admin',permissons_set:  [PermissionSet::MANAGE_ORGANIZATION]})
        UserRepository.persist @user

        sanctioning_body.sanction(org)
        SanctioningBodyRepository.persist sanctioning_body

        sign_in(@account)
      end

      it "calls the action with the right parameters" do
        obj = PermissionObject.new(@user,  @org, [PermissionSet::MANAGE_STAFF])
        mock_execute_action(KyckRegistrar::Actions::GetOrganizations, {order: "updated_at", order_dir:'asc', limit: 25, offset: 0, conditions: {}}, [@org])
        get :index, sanctioning_body_id: sanctioning_body.id, format: :json, orderby: "updated_at", dir: "asc"

        json.count.should == 1
        json[0]["id"].should == @org.id.to_s
      end
    end
  end

  describe "#update" do
    let(:org) { create_club }
    let(:requestor) { regular_user }
    let(:new_values) {{name: "New Name", url: "http://belowme.com"} }
    context "when the user has permission" do
      before(:each) do
        add_user_to_org(requestor, org, title: 'Admin', permission_sets: [PermissionSet::MANAGE_ORGANIZATION])
      end

      it "calls the right action" do
        # So, no idea why this works, but it does
        stub_wisper_publisher("KyckRegistrar::Actions::UpdateOrganization", :execute, :organization_updated, org, org._data.props, new_values)
        put :update, id: org.kyck_id, organization: new_values
      end

      it "redirects to the organization page" do
        mock_action = stub_wisper_publisher("KyckRegistrar::Actions::UpdateOrganization", :execute, :organization_updated, org, org._data.props, new_values)
        put :update, id: org.kyck_id, organization: new_values
        response.should redirect_to(organization_path(org))
      end

      context "when json is the format" do
        it "responds with json" do
          # So, no idea why this works, but it does
          stub_wisper_publisher("KyckRegistrar::Actions::UpdateOrganization", :execute, :organization_updated, org, org._data.props, new_values)
          put :update, id: org.kyck_id, organization: new_values, format: :json
          assert_not_nil json['name']
        end

        context "and there are errors" do
          it "responds with json" do
            # So, no idea why this works, but it does
            # Fuck You, Wisper
            stub_wisper_publisher("KyckRegistrar::Actions::UpdateOrganization", :execute, :invalid_organization, org, org._data.props, new_values)
            org.stub(:errors) { { "email" => ["has been taken" ] } }
            put :update, id: org.kyck_id, organization: new_values, format: :json
            assert_not_nil json['errors']
            assert_equal 422, response.status
          end
        end
      end

      context "when the org is sanctioned" do
        before do
          Organization.any_instance.stub(:sanctioned?) {true}
        end

        context "when the name changes" do
          it "notifies USCS" do
            KyckMailer.should_receive(:organization_name_changed!)
            put :update, id: org.kyck_id, organization: new_values

          end
        end
      end
    end
  end

  describe "#destroy" do
    let(:org) { create_club }
    let(:requestor) { regular_user }
    context "when the user has permissions.." do
      before(:each) do
        add_user_to_org(requestor, org, title: 'Admin', permission_sets: [PermissionSet::MANAGE_ORGANIZATION])
      end

      it "calls the right action" do
        mock_execute_action(KyckRegistrar::Actions::RemoveOrganization, nil, nil)
        delete :destroy, id: org.kyck_id
      end
    end

  end
end

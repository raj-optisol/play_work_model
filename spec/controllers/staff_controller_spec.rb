require 'spec_helper'

describe StaffController, type: :controller do
  include Devise::TestHelpers

  before(:each) do
    @org = create_club
  end

  def sign_in_user_with_manage_staff_for_org(org)
    @account = create_account
    @user = regular_user({kyck_id: @account.kyck_id.to_s})
    @staff = org.add_staff(@user, {title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
    UserRepository.persist @user
    sign_in(@account)
    @user
  end

  describe "#new" do
    it "should assign @staff" do
      get :new, organization_id: @org.kyck_id.to_s
    end
  end

  describe "#create" do
    context "when the user is already on KYCK" do
      let(:user_to_add) { regular_user}
      before(:each) do
        sign_in_user_with_manage_staff_for_org(@org)
      end

      it "redrects to organization staff index" do
        stub_wisper_publisher("KyckRegistrar::Actions::AddStaff", :execute, :staff_created, Staff.build )
        post :create, organization_id: @org.kyck_id.to_s, staff: {user_id: user_to_add.id}
        response.should redirect_to organization_staff_index_path(@org.kyck_id)
      end

      context "when the notifcation fails" do

        it "sets a flash message" do
          stub_wisper_publisher("KyckRegistrar::Actions::AddStaff", :execute, :notification_failed, StandardError.new )
          post :create, organization_id: @org.kyck_id.to_s, staff: {user_id: user_to_add.id}
          flash[:error].should =~ /notification failed/

        end

      end
    end

    context "when the user is not already on KYCK" do
      let(:staff_attributes)  {
        {
          first_name: "Fred",
          last_name: "Flinstone",
          email: 'fred@flintstone.com',
          title: 'Coach',
          phone: '704-555-5555'}
      }

      context "when a staff user with right permissions is logged in" do
        before(:each) do
          sign_in_user_with_manage_staff_for_org(@org)
          stub_wisper_publisher("KyckRegistrar::Actions::AddStaff", :execute, :staff_created, Staff.build )
        end

        it "redirects to the organization staff page" do
          post :create, organization_id: @org.kyck_id.to_s, staff: staff_attributes
          response.should redirect_to organization_staff_index_path(@org)
        end

        context "but the paras are not valid" do
          before(:each) do
            stub_wisper_publisher("KyckRegistrar::Actions::AddStaff", :execute, :invalid_staff, Staff.build )
          end

          it "redirects to new staff" do
            staff_attributes.delete(:email)
            post :create, organization_id: @org.kyck_id.to_s, staff: staff_attributes
            response.should redirect_to new_organization_staff_path(@org)
          end


        end

      end

      context "when a user does not have permisson" do
        before(:each) do
          sign_in_user(regular_user)
        end

        it "should raise the error" do
          stubbed_action = stub_execute_action(KyckRegistrar::Actions::AddStaff, nil, nil, KyckRegistrar::PermissionsError)
          stubbed_action.stub(:on)

          expect {post :create, organization_id: @org.kyck_id.to_s, staff: staff_attributes}.to raise_error KyckRegistrar::PermissionsError
        end

      end

    end
  end

  describe "#index" do

    before(:each) do
      @account = create_account
      @user = regular_user({kyck_id: @account.kyck_id.to_s})
      sign_in(@account)
      @staff = @org.add_staff(@user, {title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
      @user1 = regular_user
      @user2 = regular_user
    end

    it 'should display an alphabetized list of staff members' do
      @staff2 = @org.add_staff(@user, {title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
      mock_execute_action(KyckRegistrar::Actions::GetStaff, nil, [@staff2, @staff])
      get :index, organization_id: @org.kyck_id.to_s, format: :json
      res = JSON.parse(response.body)
      res.map{ |x| x["first_name"] }.should == [@staff2, @staff].map{ |x| x.user.first_name }.sort
    end

    describe "when an organization is not specified" do
      before(:each) do
        @staff1 = @org.add_staff(@user1, {title: 'President', permission_sets:  ["ManageStaff"]})
        OrganizationRepository.persist @org
      end

      it "calls the right action" do
        mock_execute_action(KyckRegistrar::Actions::GetStaff, nil, [])
        get :index, organization_id: @org.kyck_id.to_s, format: :json
      end
    end

    describe "for an organization" do
      describe "when the user is part of the org" do

        describe "and has permission to manage staff" do

          before(:each) do
            @staff1 = @org.add_staff(@user1, {title: 'President', permission_sets: ["ManageOrganization"]})
            @staff2 = @org.add_staff(@user2, {title: 'Coach', permission_sets: ["ManageTeam"]})
            OrganizationRepository.persist @org
            @staff_not_in_org = regular_user
          end

          it "should not include staff not in my org " do
            get :index, organization_id: @org.kyck_id.to_s, format: :json
            json.map! {|s| s["id"]}.should_not include(@staff_not_in_org.id)
          end

          it "should include staff in my org " do
            get :index, organization_id: @org.kyck_id.to_s, format: :json
            ids = json.map {|s| s["id"]}
            ids.should include(@staff1.kyck_id.to_s)
            ids.should include(@staff2.kyck_id.to_s)
          end
        end
      end
    end

  end

  describe "#edit" do
    context "for an organization" do
      before(:each) do
        @staffuser = regular_user
        @staff = @org.add_staff(@staffuser, {title: "Big Dog"})
        OrganizationRepository.persist @org
        sign_in_user_with_manage_staff_for_org(@org)
        Oriented.graph.commit
      end

      it "should assign the org" do
        get :edit, organization_id: @org.kyck_id.to_s, id: @staff.kyck_id.to_s
        assigns(:org).kyck_id.should == @org.kyck_id
      end

      it "should assign the staff" do
        get :edit, organization_id: @org.kyck_id.to_s, id: @staff.kyck_id.to_s
        assigns(:staff).kyck_id.should == @staff.kyck_id.to_s
      end
    end

    context "for a sanctioning body" do
      before(:each) do
        @staffuser = regular_user
        @org = create_sanctioning_body
        @staff = @org.add_staff(@staffuser, {title: "Big Dog"})
        SanctioningBodyRepository.persist @org
        sign_in_user_with_manage_staff_for_org(@org)
        Oriented.graph.commit
      end

      it "should assign the org" do
        get :edit, sanctioning_body_id: @org.kyck_id.to_s, id: @staff.kyck_id.to_s
        assigns(:obj).kyck_id.should == @org.kyck_id
      end

      it "should assign the staff" do
        get :edit, sanctioning_body_id: @org.kyck_id.to_s, id: @staff.kyck_id.to_s
        assigns(:staff).kyck_id.should == @staff.kyck_id.to_s
      end

    end
  end

  describe "#update" do
    let(:staff_attrs) {
      {id: @staff_to_change.kyck_id, first_name: 'Bob', last_name: 'Newhart', phone_number: '555-555-5555', email: 'b@b.com', title: 'King', permission_sets: [] }.stringify_keys
    }

    before(:each) do
      @staffuser = regular_user
      @staff_to_change = @org.add_staff(@staffuser, {title: "Big Dog"})
      OrganizationRepository.persist @org
      sign_in_user_with_manage_staff_for_org(@org)
    end

    it "should call the update action" do
      stub_wisper_publisher("KyckRegistrar::Actions::UpdateStaff", :execute, :staff_updated, @staffuser)
      put :update, organization_id: @org.kyck_id.to_s, id: @staff_to_change.kyck_id.to_s, staff: staff_attrs
    end

    it "should redirect to organization staff page" do
      put :update, organization_id: @org.kyck_id.to_s, id: @staff_to_change.kyck_id.to_s, staff: staff_attrs
      response.should redirect_to organization_staff_index_path(@org)
    end

  end

  describe "#destroy" do

    before(:each) do
      @staffuser = regular_user
      @staff_to_delete = @org.add_staff(@staffuser, {title: "Big Dog"})
      @org = OrganizationRepository.persist @org

      @action = Object.new
      @action.should_receive(:execute).with(an_instance_of(Hash))
      KyckRegistrar::Actions::RemoveStaff.stub(:new) {@action}

      sign_in_user_with_manage_staff_for_org(@org)
    end

    subject {delete :destroy, organization_id: @org.kyck_id.to_s, id: @staff_to_delete.id}

    it "should call the action to remove the staff" do
      subject
    end

    it "should show a success message" do
      subject
      flash[:notice].should =~ /successfully removed/
    end
  end
end

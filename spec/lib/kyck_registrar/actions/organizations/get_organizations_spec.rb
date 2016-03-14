require 'spec_helper'

describe KyckRegistrar::Actions::GetOrganizations do

  let(:org) {create_club}
  let(:requestor) {regular_user}

  describe "for a admin user with right to manage organizations" do
    before(:each) do
      @user = admin_user([PermissionSet::MANAGE_ORGANIZATION])
    end

    it 'should return all organizations ' do
      input = {}
      org
      action = KyckRegistrar::Actions::GetOrganizations.new @user
      results = action.execute input
      results.count.should == 1
    end
  end

  describe "requesting orgs the user can manage" do
    before(:each) do
      @user = regular_user
      st1 = org.add_staff(@user, {title: "Registrar", permission_sets: [PermissionSet::MANAGE_ORGANIZATION, 'ManageTeams', 'ManagePlayers', 'ManageStaff', 'ManageRosters']})

      UserRepository.persist(@user)
      @org1 = create_club
      st2 =  @org1.add_staff(@user, {title: "Registrar",permission_sets: [PermissionSet::MANAGE_ORGANIZATION, 'ManageTeams', 'ManagePlayers', 'ManageStaff', 'ManageRosters']})
      UserRepository.persist(@user)

      org2 = create_academy
      st3 =  org2.add_staff(@user, {title: "Coach", permission_sets: ['ManagePlayers', 'ManageRosters']})
      UserRepository.persist!(@user)
    end

    it 'retuns the orgs the user is a part of' do
      action = KyckRegistrar::Actions::GetOrganizations.new @user
      results = action.execute
      results.count.should == 3
    end

    it 'should return organizations that user can manage' do
      input = {permission_sets: [ PermissionSet::MANAGE_ORGANIZATION ]}
      action = KyckRegistrar::Actions::GetOrganizations.new @user
      results = action.execute input
      results.count.should == 2
    end

    context "when the user is an admin" do
      let(:requestor) {admin_user}

      it "returns all organizations" do
        input = {}
        action = KyckRegistrar::Actions::GetOrganizations.new requestor
        results = action.execute(input)
        results.count.should == OrganizationRepository.all.count
      end
    end
  end

  describe "when a sanctioning_body is supplied" do
     let(:sanctioning_body) {create_sanctioning_body}
     subject {described_class.new(requestor, sanctioning_body).execute({})}
     let(:other_org) {create_club}

     before(:each) do
       add_user_to_org(requestor, sanctioning_body, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_ORGANIZATION]})
       sanctioning_body.sanction(org)
       SanctioningBodyRepository.persist! sanctioning_body
     end

     it "returns the sanctioned orgs" do
       subject.first.id.should == org.id
     end

     it "should not return unsanctioned clubs" do
       subject.count.should == 1
     end
   end

  describe "when requesting for a user" do
    context "and the user is an admin" do
      let(:requestor) {admin_user}
      let(:user) { regular_user}
      let(:other_org) {create_club}

      before do
        add_user_to_org(user, other_org)
      end

      it "returns all organizations for that user" do
        input = {user_id: user.kyck_id}
        action = KyckRegistrar::Actions::GetOrganizations.new requestor
        results = action.execute(input)
        results.count.should == 1
        results.first.kyck_id.should == other_org.kyck_id
      end

    end

  end
end

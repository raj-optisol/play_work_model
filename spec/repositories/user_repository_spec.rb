require 'spec_helper'
require_relative '../../app/repositories/user_repository'

describe UserRepository do

  describe "admins" do
    let(:sb) {create_sanctioning_body}
    let(:st) {sanctioning_body_create_state(sb)}
    before :each do
      @admin = regular_user
      @representative = regular_user
      @user = regular_user
      Oriented.graph.commit
      res = st.add_staff(@admin, :role => 'Admin')
      OrganizationRepository::StaffRepository.persist(res)
      res = st.add_staff(@representative, :role => 'Representative')
      OrganizationRepository::StaffRepository.persist(res)
      Oriented.graph.commit
      @users = described_class.sb_admins
    end

    it "should return all users having an admin staff_for relationship to a state of a sanctioning body" do
      expect(@users.map(&:kyck_id)).to include(@admin.kyck_id)
    end

    it "should not return any users not having an admin staff_for relationship to a state of a sanctioning body" do
      expect(@users.map(&:kyck_id)).not_to include(@user.kyck_id)
      expect(@users.map(&:kyck_id)).not_to include(@representative.kyck_id)
    end
  end

  describe "get_recipients_for_obj" do
    before(:each) do
      @user = regular_user
      @org = create_club

      @team = Team.build(name: 'New Team')
      @org.add_team(@team)
      OrganizationRepository.persist @org

      @staff = @team.add_staff(regular_user, {title:"Coach"})
      @roster = @team.create_roster({name: 'A Roster'})
      OrganizationRepository::TeamRepository.persist @team

      user = regular_user
      user2 = regular_user

      player1 = @roster.add_player(user)
      player2 = @roster.add_player(user2)
      TeamRepository::RosterRepository.persist @roster

    end

    it "should return all the players and staff for the team when user is just an admin" do
      admin = admin_user
      sta = @org.add_staff(admin, {permission_sets:['ManageTeams']})
      objs = described_class.get_recipients_for_obj(admin, @team)
      objs.count.should == 3
    end

    it "should return all the players and staff for the team except for the sender" do
      player = @roster.add_player(@user)
      UserRepository.persist @user
      objs = described_class.get_recipients_for_obj(@user, @team)
      objs.count.should == 3
    end

    it "should raise permissions error when user isn't on team or staff of team" do
      expect { described_class.get_recipients_for_obj(@user, @team)}.to raise_error KyckRegistrar::PermissionsError
    end
  end
end

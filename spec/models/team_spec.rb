require 'spec_helper'

describe Team do
  subject do
    t = Team.build(name: 'New Team')
    t
  end

  it "has a staff" do
    Team.build(name: 'Buckets').staff.should == []
  end

  describe "#add_staff" do

    let(:user) {regular_user}

    it "adds the staff" do
      expect {
        s = subject.add_staff(user, title: "Coach", permission_sets: [ PermissionSet::MANAGE_TEAM ])
        OrganizationRepository::StaffRepository.persist(s)
        subject._data.reload
      }.to change{subject.staff.count}.by(1)
    end

  end

  describe "#remove_staff" do
    before(:each) do
      @team = Team.build(name: 'New Team')
      @team = OrganizationRepository::TeamRepository.persist @team
      @user = regular_user
      @team.add_staff(@user, title: 'Coach')
      @user = UserRepository.persist @user


    end

    it "should remove the relatioship" do
      expect {
        @team.remove_staff(@user)
        @team._data.reload
        OrganizationRepository::TeamRepository.persist @team
      }.to change {@team.get_staff.count}.by(-1)
    end

  end

  describe "#create_roster" do
    it "should create a new roster for the team" do
      expect {
        r = subject.create_roster(name: "Roster 1")
      }.to change{subject.rosters.count}.by(1)
    end
  end

  describe "#clone_roster" do
    let(:roster) {create_roster_for_team(subject, {name:"roster 1"})}
    let(:player) { regular_user }

    before(:each) do
      add_user_to_roster(roster, player, {position:"forward"})
    end

    it "should create a new roster for the team" do
        r = subject.clone_roster(roster, {name: "Roster Clone"})
        r.players.count.should == 1
        subject.rosters.count.should == 2

    end
  end

  describe "#get_or_create_master_schedule" do
    it "should create a new master schedule for the team" do
      expect {
        subject.get_or_create_master_schedule()
      }.to change{subject.schedules.count}.by(1)
    end
  end

  describe "#get_roster_by_id" do
    before(:each) do
      $roster1 = subject.create_roster(name: "Roster 1")
      $roster2 = subject.create_roster(name: "Roster 2")
    end

    it "should return the right roster" do
      subject.get_roster_by_id($roster2.id).id.should == $roster2.id

    end
  end

end

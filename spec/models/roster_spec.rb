require 'spec_helper'
require_relative '../../app/models/roster'

describe Roster do
  subject {Roster.build(name: 'My Roster')}

  it "has a name" do
    subject.name.should == 'My Roster'
  end

  describe "players" do
    before(:each) { OrganizationRepository.persist subject }
    let(:user) {regular_user}

    it "can be added to a roster" do
      expect {
        p = subject.add_player(user, position: "Keeper")
        OrganizationRepository::PlayerRepository.persist(p)
      }.to change {subject.players.count}.by(1)
    end

    it "sets the position" do
        rel = subject.add_player(user, position: "Keeper")
        rel.position.should == "Keeper"
      end

      it "can be removed from a roster" do
        subject.add_player(user, position: "Keeper")
        TeamRepository::RosterRepository.persist(subject)
        expect {
          subject.remove_player(user)
          subject._data.reload
          TeamRepository::RosterRepository.persist(subject)
        }.to change{subject.players.count}.by(-1)
      end

  end

    describe "staff" do
       before(:each) { TeamRepository::RosterRepository.persist(subject) }
       let(:user) {regular_user}

       it "can be added to a roster" do
         expect {
           p = subject.add_staff(user, title: "Keeper")
           OrganizationRepository::PlayerRepository.persist(p)
         }.to change {subject.staff.count}.by(1)
       end

       it "sets the title" do
         rel = subject.add_staff(user, title: "Coach")
         rel.title.should == "Coach"
       end

       it "sets the permission sets" do
         rel = subject.add_staff(user, title: "Coach", permission_sets: [ "ManageTeam","ManagePlayers" ])
         rel.permission_sets.to_a.should == ["ManageTeam","ManagePlayers"]
       end

       it "can be removed from a roster" do
         subject.add_staff(user, title: "Coach")
         TeamRepository::RosterRepository.persist(subject)
         expect {
           subject.remove_staff(user)
           subject._data.reload
           TeamRepository::RosterRepository.persist(subject)
         }.to change{subject.staff.count}.by(-1)
       end

     end

  describe '#sanctioned?' do
    let(:sb) { create_sanctioning_body }
    let(:org) { create_club }
    let(:team) { create_team_for_organization(org) }
    let(:roster) { create_roster_for_team(team) }

    it 'returns true if the associated organization is sanctioned' do
      create_sanction_for_sb_and_item(sb, org)
      roster.sanctioned?.should == true
    end

    it 'returns true if the associated competition entry is sanctioned' do
      comp = create_competition
      division = create_division_for_competition(comp)
      create_sanction_for_sb_and_item(sb, comp)
      entry = create_competition_entry(sb, comp, division, team, roster, { status: :approved })
      roster.sanctioned?.should == true
    end

    it 'returns false if the associated organization is not sanctioned' do
      org.sanctioned?.should == false
      roster.sanctioned?.should == false
    end

    it 'returns false if the associated organization is not sanctioned and the roster has no associated competition entry' do
      roster.competition_entry.should be_nil
      roster.sanctioned?.should == false
    end

    it 'returns false if the associated competition is not sanctioned' do
      comp = create_competition
      division = create_division_for_competition(comp)
      entry = create_competition_entry(sb, comp, division, team, roster, { status: :approved })
      comp.sanctioned?.should == false
      roster.sanctioned?.should == false
    end
  end
end

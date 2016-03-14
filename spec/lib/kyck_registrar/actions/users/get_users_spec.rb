require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetUsers do

      let(:club) { create_club }
      let(:requestor) { regular_user }
      describe ".new" do
        it "should require a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "should require a playable object" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        context "for a club" do
          subject { described_class.new(requestor, club) }
          let(:team) { create_team_for_organization(club)}
          let(:roster) { create_roster_for_team(team, official: true)}

          before do
            roster
            add_user_to_org(requestor, club, permission_sets: [PermissionSet::MANAGE_ROSTER])
            @user = regular_user
            player = club.add_player(@user)
            player._data.save
            @user2 = regular_user
            player2 = roster.add_player(@user2)
            TeamRepository::RosterRepository.persist roster 
            OrganizationRepository::TeamRepository.persist club.open_team
            OrganizationRepository.persist club
            puts club.open_team.official_roster.players.count
            Oriented.graph.commit
          end

          it "should return all the users for the club" do
            users = subject.execute(kind:"players")
            users.count.should == 2
          end
        end
      end  # END EXECUTE
    end
  end
end

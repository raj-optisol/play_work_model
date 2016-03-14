# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemovePlayer do
      let(:requestor) { regular_user }
      let(:org) { create_club }
      let(:team) { create_team_for_organization(org) }
      let(:official_roster) { create_roster_for_team(team, official: true) }
      let(:roster) { create_roster_for_team(team, official: false) }

      describe '#initialize' do
        it 'takes a requestor and an object' do
          expect do
            described_class.new(requestor, official_roster)
          end.to_not raise_error
        end
      end

      describe 'execute' do
        let(:player_user) { regular_user }
        before(:each) do
          add_user_to_org(requestor,
                          org,
                          permission_sets: [PermissionSet::MANAGE_PLAYER])

          @player = official_roster.add_player(player_user)
          @player2 = roster.add_player(player_user)
          UserRepository.persist(player_user)
        end

        context 'for a roster' do
          subject { described_class.new(requestor, roster) }

          it 'removes the player from just this roster' do
            subject.execute(id: @player2.kyck_id)
            assert_equal roster.players.count, 0
            official_roster.players.count.should == 1
          end

          context 'that is official' do
            subject { described_class.new(requestor, official_roster) }

            it 'removes the player' do
              subject.execute(id: @player.kyck_id)
              assert_equal roster.players.count, 0
              assert_equal official_roster.players.count, 0
            end
          end
        end

        context 'for a team' do
          subject { described_class.new(requestor, team) }
          it 'removes the player' do
            subject.execute(id: @player.kyck_id)
            assert_equal roster.players.count, 0
            official_roster.players.count.should == 0
          end

          it 'adds the player to the open roster for the club' do
            subject.execute(id: @player.kyck_id)
            Oriented.graph.commit
            player_ids = org.open_team.get_players.map { |p| p.user.kyck_id}
            player_ids.should include(@player.user.kyck_id)
          end

          context "when the player is on multiple teams" do
            let(:team2) { create_team_for_organization(org) }
            let(:official_roster2) { create_roster_for_team(team2, official: true) }
            before do
              @player2 = official_roster2.add_player(player_user)
              UserRepository.persist(player_user)
            end

            it "just removes the player from that team" do
              assert_equal player_user.plays_for.count, 3
              assert_equal org.open_team.get_players.count, 0
              subject.execute(id: @player.kyck_id)
              Oriented.graph.commit
              roster._data.reload
              official_roster._data.reload
              assert_equal roster.players.count, 0
              official_roster.players.count.should == 0
              org.open_team.get_players.count.should == 0
            end
          end
        end
      end # END EXECUTE
    end
  end
end

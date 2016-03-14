require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetPlayers do

      let(:org) { create_club }
      let(:requestor) { regular_user }
      let(:team) { create_team_for_organization(org) }
      let(:roster) { create_roster_for_team(team, official: true) }
      let(:player1) do
        add_player_to_roster( roster,
                             { first_name:"player 1",
                               last_name:"one",
                               kyck_id:"p11",
                               email:"oneplayer.com" },
                               position: 'forward')
      end
      let(:player2) do
        add_player_to_roster(roster,
                             { first_name:"player 2",
                               last_name:"two",
                               kyck_id:"p22",
                               email:"twoplayer.com" },
                               position: 'midfielder')
      end
      let(:player3) { create_player_for_organization(org) }

      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        before do
          player1
          player2
        end

        context "roster" do
          describe "when no filters are provided" do
            it "gets all when user is a player on the roster" do
              roster.add_player(requestor, position:'midfielder')
              UserRepository.persist(requestor)
              results = described_class.new(requestor, roster).execute({})
              results.count.should == 3
            end

            it "returns wrapped players" do
              roster.add_player(requestor, {position:'midfielder'})
              UserRepository.persist(requestor)
              results = described_class.new(requestor, roster).execute({user_conditions:{last_name:"two"}})
              results.first.should be_a(Player)
            end

            it "filters by player attributes" do
              roster.add_player(requestor, {position:'midfielder'})
              UserRepository.persist!(requestor)
              results = described_class.new(requestor, roster).execute(player_conditions: { position:"forward" })
              results.count.should == 1
            end

            it "filters by player id" do
              p = roster.add_player(requestor, {position:'midfielder'})
              p2 = roster.add_player(regular_user, {position:'goalie'})
              p2._data.save
              UserRepository.persist(requestor)
              results = described_class.new(requestor, roster).execute({player_conditions:{kyck_id: p.kyck_id}})
              results.count.should == 1
            end

            it "filters by user attributes" do
              roster.add_player(requestor, {position:'midfielder'})
              UserRepository.persist(requestor)
              results = described_class.new(requestor, roster).execute({user_conditions:{last_name:"one"}})
              results.count.should == 1
            end

            it "throws permission error when user is not part of roster or staff for hierarchy" do
              expect { described_class.new(requestor, roster).execute({}) }.to raise_error PermissionsError
            end
          end
        end

        context "team" do
          describe "when no filters are provided" do
            before do
              add_user_to_org(requestor, team)
            end

            it "gets all when user is player for roster" do
              team._data.reload
              results = described_class.new(requestor, team).execute({})
              results.count.should == 2
            end
          end
        end

        context "organization" do
          describe "when no filters are provided" do
            it "gets all players connected to organization" do
              player3
              org.add_staff(requestor)
              UserRepository.persist(requestor)
              results = described_class.new(requestor, org).execute
              results.count.should == 3
            end

            it "throws permission error when user is not part of roster or staff for hierarchy" do
              expect { described_class.new(requestor, org).execute({}) }.to raise_error PermissionsError
            end

            it "throws permission error when user is not staff org or hierarchy" do
              open_team = OrganizationRepository::TeamRepository.open_team_for_org!(org)
              open_team.official_roster.add_player(requestor, {position:'midfielder'})
              UserRepository.persist(requestor)
              expect { described_class.new(requestor, org).execute({}) }.to raise_error PermissionsError
            end

          end
        end

        context "requestor" do
          describe "when no filters are provided" do
            it "gets all players connected to user" do
              roster.add_player(requestor)
              UserRepository.persist(requestor)
              results = described_class.new(requestor).execute({})
              results.count.should == 1
            end
          end
        end
      end
    end
  end
end

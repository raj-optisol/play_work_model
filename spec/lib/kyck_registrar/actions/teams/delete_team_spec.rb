# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe DeleteTeam do

      describe '#new' do
        it 'should take a requestor' do
          expect { described_class.new }.to raise_error ArgumentError
        end
      end

      describe '#execute' do
        let(:club) { create_club }
        let(:team) { create_team_for_organization(club) }
        let(:roster) { create_roster_for_team(team, name: 'Official Roster', official: true) }
        let!(:player) { add_player_to_roster(roster) }

        subject { described_class.new(requestor, team) }

        context 'when the requestor has permission to delete the team' do
          let(:requestor) do
            staff = club.add_staff(
              regular_user,
              title: 'Manager',
              permission_sets: [PermissionSet::MANAGE_TEAM]
            )
            OrganizationRepository.persist(club)
            staff.user
          end

          it 'should tell the repo to delete the team' do
            mock = double
            mock.should_receive(:destroy_team).with(team)

            subject.repository = mock

            subject.execute
          end

          context "when the team is open" do
            before do
              team.open = true
              team._data.save
            end

            it "raises an error" do
              expect { subject.execute }.to raise_error
            end
          end

        end

        context 'when the requestor does not have permission' do
          let(:requestor) { regular_user }

          it 'should raise an error' do
            action = described_class.new(requestor, team)
            expect { action.execute }.to raise_error PermissionsError
          end
        end
      end
    end
  end
end

require 'spec_helper'
module KyckRegistrar
  module Actions
    describe GetTeams do
      it 'requires a requestor' do
        expect{described_class.new}.to raise_error ArgumentError
      end

      describe '#execute' do
        let(:requestor) { regular_user }
        let(:club) { create_club }
        let!(:team) { create_team_for_organization(club) }

        describe 'when the requestor has the required permisson' do
          before(:each) do
            add_user_to_org(
              requestor,
              club,
              title:'Coach',
              permission_sets: [PermissionSet::MANAGE_TEAM]
            )
          end

          context 'for an organization' do
            it 'returns the current teams for an organization' do
              action = described_class.new(requestor, club)
              teams = action.execute()
              teams.count.should == 1
            end

            describe 'when search parameters are supplied' do
              let(:other_team){ create_team_for_organization(club) }

              it 'should filter the results' do
                action = described_class.new(requestor, club)
                teams = action.execute(conditions: { name_like: team.name })
                teams.count.should == 1
                teams.first.id.should == team.id
              end
            end
          end

          context 'for a competition' do
            let(:comp) { create_competition }
            let(:div) { create_division_for_competition(comp) }
            let(:roster) { create_roster_for_team(team)}
            let!(:entry) do
              create_competition_entry(requestor, comp, div, team, roster)
            end

            it 'returns the teams in the competition' do
              action = described_class.new(requestor, comp)
              teams = action.execute
              assert teams.count == 1
              teams.first.kyck_id.should == team.kyck_id
            end
          end
        end
      end
    end
  end
end

require 'spec_helper'

module Teams
  module Competitions
    describe CompetitionEntriesController do

      let(:requestor) { regular_user }
      let(:club) { create_club }
      let(:team) { create_team_for_organization(club) }
      let(:roster) { create_roster_for_team(team) }
      let(:competition) { create_competition }
      let(:division) { create_division_for_competition(competition) }

      before do
        sign_in_user(requestor)
      end

      describe "#create" do
        it 'creats the request for the team to be in the competition' do
          parms = { "roster_id" => roster.kyck_id, "division_id" => division.kyck_id }
          mock_execute_action(KyckRegistrar::Actions::RequestCompetitionEntry,
                              parms, competition)

          post(:create,
               team_id: team.kyck_id,
               competition_id: competition.kyck_id,
               roster_id: roster.kyck_id,
               division_id: division.kyck_id,
               start_with: 'team')
        end
      end
    end
  end
end

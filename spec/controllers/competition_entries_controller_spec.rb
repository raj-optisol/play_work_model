require 'spec_helper'

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

  describe "#index" do
    before do
      add_user_to_org(requestor,
                      competition,
                      permission_sets: PermissionSet::MANAGE_REQUEST)
    end

    let!(:entry) do
      create_competition_entry(requestor, competition, division, team, roster)
    end
    it "shows the entries for a competition" do
      get :index, competition_id: competition.kyck_id, format: :json
      json.map { |e| e["id"] }.should include(entry.kyck_id)
    end
  end

end

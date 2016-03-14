# encoding: UTF-8
require 'spec_helper'

describe TeamsController do
  include Devise::TestHelpers

  let(:org) { create_club }
  let(:user) { regular_user }
  before(:each) do
    sign_in_user(user)
  end

  describe '#index' do
    let(:team1) { create_team_for_organization(org) }
    let(:team2) { create_team_for_organization(org) }
    let(:team3) { create_team_for_organization(org) }

    context 'for a competition' do
      let(:parms) do
        {
          limit: 25,
          offset: 0,
          conditions: {},
          order: 'name',
          order_dir: 'asc' }
      end
      let(:comp) { create_competition }
      let(:div) { create_division_for_competition(comp) }
      let!(:entry) do
        create_competition_entry(user,
                                 comp,
                                 div,
                                 team1,
                                 team1.official_roster)
      end

      it 'calls the right action' do
        mock_execute_action(KyckRegistrar::Actions::GetTeams, parms, [team1])
        get :index, competition_id: comp.kyck_id, format: :json
      end
    end
  end
end

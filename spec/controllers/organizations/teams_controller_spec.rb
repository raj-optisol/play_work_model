# encoding: UTF-8
require 'spec_helper'
module Organizations
  describe TeamsController do
    let(:club) { create_club }
    let(:user) { regular_user }
    before(:each) do
      sign_in_user(user)
    end
    describe '#index' do
      let(:team1) { create_team_for_organization(club) }
      let(:team2) { create_team_for_organization(club) }
      let(:team3) { create_team_for_organization(club) }

      it 'returns the teams for the club' do
        mock_execute_action(KyckRegistrar::Actions::GetTeams,
                            nil,
                            [team1, team2])
        get :index, organization_id: club.kyck_id, format: :json
        ids = json.each.map { |t| t['id'] }
        ids.should include(team1.kyck_id.to_s)
        ids.should include(team2.kyck_id.to_s)
      end

      it 'returns an alphabetized list of teams' do
        mock_execute_action(
          KyckRegistrar::Actions::GetTeams,
          nil,
          [team2, team1, team3])
        get :index, organization_id: club.kyck_id, format: :json
        names = json.each.map { |t| t['name'] }
        assert_equal names, names.sort
      end

      context 'when a name filter is supplied' do
        let(:parms) do
          {
            limit: 25,
            offset: 0,
            conditions: { 'name_like' => team2.name },
            order: 'name',
            order_dir: 'asc'
          }
        end

        before(:each) do
          mock_execute_action(
            KyckRegistrar::Actions::GetTeams,
            parms,
            [team2])
        end

        it 'should filter the teams by that value' do
          get(
            :index,
            organization_id: club.kyck_id,
            filter: { name_like: team2.name }.to_json,
            format: :json)
          assert_equal json.count, 1

          json[0]['id'].should == team2.kyck_id.to_s
        end
      end
    end

    describe '#create' do
      context 'when the logged in user has manage team rights' do
        before(:each)  do
          club.add_staff(user,
                         title: 'Coach',
                         permission_sets: [PermissionSet::MANAGE_TEAM])
          OrganizationRepository.persist club
        end

        let(:team_attributes) do
          { 'name' =>  'New Team', 'gender' => 'F', 'born_after' => (Date.today - 12.years).strftime("%m/%d/%Y") }
        end

        subject do
          post :create, organization_id: club.kyck_id, team: team_attributes
        end

        it 'calls the right action' do
          mock_execute_action(KyckRegistrar::Actions::CreateTeam,
                              team_attributes)
          subject
        end

        it 'redirects to the organization teams page' do
          stub_execute_action(KyckRegistrar::Actions::CreateTeam,
                              team_attributes)
          subject
          response.should redirect_to organization_teams_path(club)
        end
      end
    end

    describe '#update' do
      let(:new_team_attributes) do
        { 'name' => 'Changed Name', 'gender' => 'M', 'born_after' => (Date.today - 14.years).strftime("%m/%d/%Y") }
      end

      let(:team) { create_team_for_organization(club) }

      context 'when the logged in user has manage team rights' do
        before(:each)  do
          club.add_staff(user,
                         title: 'Coach',
                         permission_sets: [PermissionSet::MANAGE_TEAM])
          OrganizationRepository.persist club
        end

        it 'should call the update team action' do
          mc = mock_execute_action(KyckRegistrar::Actions::UpdateTeam,
                                   new_team_attributes)
          mc.stub(:subscribe)
          put(:update,
              organization_id: club.kyck_id,
              id: team.kyck_id.to_s,
              team: new_team_attributes)
        end

        it 'should redirect to the organizations team page' do
          mc = stub_execute_action(KyckRegistrar::Actions::UpdateTeam,
                                   new_team_attributes)
          mc.stub(:subscribe)
          put(:update,
              organization_id: club.kyck_id.to_s,
              id: team.kyck_id.to_s, team: new_team_attributes)
          response.should redirect_to organization_teams_path(club)
        end
      end

      context 'when the logged in user does NOT have manage team rights' do
        let(:team) { create_team_for_organization(club) }
        before(:each)  do
          team.add_staff(user, title: 'Manager')
          OrganizationRepository::TeamRepository.persist team

          mc = mock_execute_action(KyckRegistrar::Actions::UpdateTeam,
                                   new_team_attributes)
          mc.stub(:subscribe)
        end

        it 'should redirect to the organization teams page' do
          put(:update,
              organization_id: club.kyck_id,
              id: team.kyck_id,
              team: new_team_attributes)
          response.should redirect_to organization_teams_path(club)
        end
      end
    end

    describe '#destroy' do
      let(:team) { create_team_for_organization(club) }
      context 'when the logged in user has manage team rights' do
        before(:each)  do
          club.add_staff(user,
                         title: 'Coach',
                         permission_sets: [PermissionSet::MANAGE_TEAM])
          OrganizationRepository.persist club
        end

        it 'should call the delete action' do
          mock_execute_action(KyckRegistrar::Actions::DeleteTeam)
          delete :destroy, organization_id: club.kyck_id, id: team.kyck_id
        end

        it 'redirects to the organization team page' do
          stub_execute_action(KyckRegistrar::Actions::DeleteTeam)
          delete :destroy, organization_id: club.kyck_id, id: team.kyck_id
          response.should redirect_to organization_teams_path(club)
        end

        context 'json'  do
          it 'should respond right' do
            stub_execute_action(KyckRegistrar::Actions::DeleteTeam)
            delete(:destroy,
                   organization_id: club.kyck_id,
                   id: team.kyck_id,
                   format: :json)
            response.status.should == 204
          end
        end
      end
    end

    describe '#edit' do
      let(:team) { create_team_for_organization(club) }

      context 'when the logged in user has manage team rights' do
        before(:each)  do
          club.add_staff(user,
                         title: 'Coach',
                         permission_sets: [PermissionSet::MANAGE_TEAM])
          OrganizationRepository.persist club
        end

        it 'should assign the team' do
          get :edit, organization_id: club.kyck_id, id: team.kyck_id
          expect(assigns(:team)).to_not be_nil
        end
      end

      context 'when the logged in user does not have manage team rights' do
        before(:each)  do
          team.add_staff(user, title: 'Manager')
          OrganizationRepository::TeamRepository.persist team
        end

        it 'should redirect to the organization teams page' do
          get :edit, organization_id: club.kyck_id.to_s, id: team.kyck_id.to_s
          response.should redirect_to organization_teams_path(club)
        end
      end
    end
  end
end

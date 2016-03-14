# encoding: UTF-8
require 'spec_helper'

describe PlayersController do
  include Devise::TestHelpers

  let(:org) { create_club }
  let(:team) { create_team_for_organization(org) }
  let(:roster) { create_roster_for_team(team) }

  def sign_in_user_with_manage_players_for_org(org)
    @user = regular_user
    @staff = org.add_staff(@user,
                           title: 'Registrar',
                           permission_sets:  [PermissionSet::MANAGE_PLAYER])
    UserRepository.persist @user
    sign_in_user(@user)
    @user
  end

  describe '#edit' do
    before(:each) do
      sign_in_user_with_manage_players_for_org(org)
    end

    subject do
      get :edit, roster_id: roster.kyck_id, id: player.kyck_id
    end

    let(:player_params) { { position: 'Middie', number: '10' } }

    let(:player_user) { regular_user }
    let(:player) do
      p =  roster.add_player(player_user, position: 'Keeper', number: '5')
      UserRepository.persist p
    end

    context 'when the user has rights to manage players' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
        stub_execute_action(
          KyckRegistrar::Actions::GetPlayers,
          { player_conditions: { kyck_id: player.kyck_id } },
          [ player ])
      end

      it 'is successful' do
        subject
        response.status.should == 200
      end

      it 'assigns the player' do
        subject
        assigns(:player).id.should == player.kyck_id
      end
    end

    context 'when the player is not found' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
        stub_execute_action(
          KyckRegistrar::Actions::GetPlayers,
          { player_conditions: { kyck_id: 'not-a-real-player' }},
          [  ])
      end
      it 'say not found' do
        get :edit, roster_id: roster.kyck_id, id: 'not-a-real-player'
        response.status.should == 404
      end
    end

    context 'when the user does not have the right to manage players' do
      before(:each) do
        sign_in_user(regular_user)
      end

      it 'redirects' do
        subject
        response.status.should == 302
      end
    end
  end

  describe '#create' do
    let(:player_attributes) {
      {
        first_name: 'Pebbles',
        last_name: 'Flintstone',
        player_email: 'pebbles@bedrockisp.com',
        gender: 'F',
        birthdate: 12.years.ago.to_s
      }.stringify_keys
    }

    context 'for a roster' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
      end

      context 'when the user has rights to manage players' do
        context 'with valid params' do
          before do
            stub_wisper_publisher('KyckRegistrar::Actions::AddPlayer', :execute, :player_created, Player.build )
          end

          context 'when the user exists in the system' do
            let(:new_player) {regular_user}

            it 'calls the right action with the user id' do
              post :create, roster_id: roster.kyck_id, player: {user_id: new_player.kyck_id}
            end
          end

          context 'when the user does not exist' do
            it 'calls the create player action with the attributes' do
              post :create, roster_id: roster.kyck_id, player: player_attributes
            end
          end

          it 'redirects to roster players page' do
            post :create, roster_id: roster.kyck_id, player: player_attributes
            response.should redirect_to roster_players_path(roster)
          end
        end

        context 'when the user params are invalid' do
          before do
            stub_wisper_publisher('KyckRegistrar::Actions::AddPlayer', :execute, :invalid_player, Player.build )
          end

          it 'redirects to new' do
            post :create, roster_id: roster.kyck_id, player: player_attributes
            response.should redirect_to new_roster_player_path(roster)
          end
        end
      end
    end
  end

  describe '#index' do
    before(:each) do
      sign_in_user_with_manage_players_for_org(team)
      @player = roster.add_player(regular_user, {gender: 'M'})
    end

    context "for a team", broken: true do
      it "is successful" do
        mock_execute_action(KyckRegistrar::Actions::GetPlayers,
                            args,
                            [@player])
        get(:index,
            team_id: team.kyck_id,
            filter: '{"last_name_like": "Smith"}',
            format: :json)
      end
    end

    context 'for a roster' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
        @player = roster.add_player(regular_user, {gender: 'M'})
      end

      it 'call the get players action' do
        stub_execute_action(KyckRegistrar::Actions::GetPlayers,
                            nil,
                            [@player])
        get :index, roster_id: roster.kyck_id, format: :json
        json[0]['id'].should == @player.kyck_id
      end

      context 'when a last_name filter is supplied' do
        let(:args) do
          { offset: 0,
            conditions: {},
            user_conditions: { last_name_like: 'Smith'} }
        end

        it 'should filter the results' do
          mock_execute_action(KyckRegistrar::Actions::GetPlayers,
                              args,
                              [@player])
          get :index,
            roster_id: roster.kyck_id,
            filter: '{"last_name_like": "Smith"}',
            format: :json
        end
      end

    end
  end

  describe '#destroy' do
    context 'for a roster' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
        @player = roster.add_player(regular_user, gender: 'M')
        @player._data.save
        TeamRepository::RosterRepository.persist roster
      end

      it 'removes the player from the team' do
        action = mock_execute_action(
          KyckRegistrar::Actions::RemovePlayer,
          id: @player.kyck_id
        )
        action.stub(:subscribe)
        delete :destroy, roster_id: roster.kyck_id, id: @player.kyck_id
      end

      it 'redirects to the roster' do
        action = stub_execute_action(
          KyckRegistrar::Actions::RemovePlayer,
          id: @player.kyck_id
        )
        action.stub(:subscribe)
        delete :destroy, roster_id: roster.kyck_id, id: @player.kyck_id
        response.should redirect_to roster_players_path(roster)
      end

    end
  end
end

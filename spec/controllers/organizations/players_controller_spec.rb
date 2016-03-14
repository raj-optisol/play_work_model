require 'spec_helper'
module Organizations
  describe PlayersController do
    def sign_in_user_with_manage_players_for_org(org)
      @user = regular_user
      @staff = org.add_staff(
        @user,
        title: 'Registrar',
        permission_sets:  [PermissionSet::MANAGE_PLAYER])
      UserRepository.persist @user
      sign_in_user(@user)
      @user
    end

    let(:org) { create_club }

    describe '#new' do
      context 'for a organization' do
        context 'when the user has rights to manage players' do
          before(:each) do
            sign_in_user_with_manage_players_for_org(org)
          end
        end

        context 'when the user does not have right to manage players' do
          before(:each) do
            sign_in_user(regular_user)
          end

          it 'redirects to root' do
            get :new, organization_id: org.kyck_id
            response.should redirect_to root_url
          end

          it 'has a message' do
            get :new, organization_id: org.kyck_id
            flash[:alert].should =~ /permission/
          end
        end
      end
    end

    describe '#index' do
      before(:each) do
        sign_in_user_with_manage_players_for_org(org)
        @player = org.add_player(regular_user, gender: 'M')
        @player._data.save
      end

      it 'call the get players action' do
        stub_execute_action(KyckRegistrar::Actions::GetPlayers, nil, [@player])
        get :index, organization_id: org.kyck_id, format: :json
        json[0]['id'].should == @player.kyck_id
      end

      context 'when a last_name filter is supplied' do
        let(:args) do
          {limit: 25,
           offset: 0,
           conditions: {},
           "onlyplays" => 'for',
           user_conditions: {last_name_like: 'Smith'}
          }
        end
        it 'should filter the results' do
          mock_execute_action(KyckRegistrar::Actions::GetPlayers, args, [@player] )
          get :index,
            organization_id: org.kyck_id,
            filter: '{"last_name_like": "Smith"}',
            format: :json
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
      context 'for a organization' do

        before(:each) do
          sign_in_user_with_manage_players_for_org(org)
          stub_wisper_publisher('KyckRegistrar::Actions::AddPlayer', :execute, :player_created, Player.build )
        end

        context 'when the user has rights to manage players' do

          context 'when the user exists in the system' do
            let(:new_player) {regular_user}

            it 'calls the right action with the user id' do
              post :create, organization_id: org.kyck_id, player: {user_id: new_player.kyck_id}
            end

          end

          context 'when the user does not exist' do
            it 'calls the create player action with the attributes' do
              post :create, organization_id: org.kyck_id, player: player_attributes
            end
          end

          it 'redirects to organization players page' do
            post :create, organization_id: org.kyck_id, player: player_attributes
            response.should redirect_to organization_players_path(org)
          end
        end
      end
    end

    describe '#update' do
      subject {
        put(:update,
            organization_id: org.kyck_id,
            id: player.kyck_id,
            player: player_params)
      }

      let(:player_params) do
        { 'position' => 'Middie', 'jersey_number' => '10' }
      end

      let(:player_user) {regular_user}
      let(:player) do
        p =  org.add_player(player_user, position: 'Keeper', number: '5')
        UserRepository.persist p
        p
      end
      context 'when the user has rights to manage players' do
        before(:each) do
          sign_in_user_with_manage_players_for_org(org)
          stub_wisper_publisher(
            'KyckRegistrar::Actions::UpdatePlayer',
            :execute,
            :player_updated,
            Player.build)
        end

        it 'calls the action' do
          subject
          expect(response).to redirect_to(action: :index)
        end
      end
    end

    describe '#release' do
      subject do
        put :release, organization_id: org.kyck_id, id: player.kyck_id
      end

      let(:player_params) do
        { 'position' => 'Middie', 'jersey_number' => '10' }
      end
      let(:player_user) { regular_user }
      let(:player) do
        p =  org.add_player player_user, position: 'Keeper', number: '5'
        UserRepository.persist p
        p
      end

      context 'when the user has rights to manage players' do
        before(:each) do
          sign_in_user_with_manage_players_for_org org
          stub_wisper_publisher(
            'KyckRegistrar::Actions::ReleasePlayer',
            :execute,
            :player_released,
            Player.build
          )
        end

        it 'calls the action' do
          subject
        end
      end
    end

    describe '#edit' do
      subject{
        get :edit, organization_id: org.kyck_id, id: player.kyck_id
      }

      let(:player_params) {
        { position: 'Middie', number: '10' }
      }

      let(:player_user) { regular_user }
      let(:player) {
        p =  org.add_player(player_user, position: 'Keeper', number: '5')
        UserRepository.persist p
      }

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
          stub_execute_action(KyckRegistrar::Actions::GetPlayers, {player_conditions: { kyck_id: 'not-a-real-player' }}, [])
        end
        it 'say not found' do
          get :edit, organization_id: org.kyck_id, id: 'not-a-real-player'
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
  end
end

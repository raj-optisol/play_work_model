require 'spec_helper'
require 'wisper/rspec/stub_wisper_publisher'

describe UsersController, type: :controller do
  include Devise::TestHelpers

  let(:org1) { create_club }
  let(:team) { create_team_for_organization(org1) }
  let(:sanctioning_body) { create_sanctioning_body }
  let(:requestor) { regular_user }

  describe '#staff_for' do

    let(:other_user) { regular_user }
    before(:each) do
      add_user_to_obj(other_user, org1)
      add_user_to_obj(other_user, sanctioning_body)
      add_user_to_obj(other_user, team)
      sign_in_user(requestor)
    end

    it 'returns the staff for the user' do
      get :staff_for, id: other_user.kyck_id, format: :json
      ids = json.map {|o| o['id']}
      ids.should include(org1.kyck_id)
      ids.should include(sanctioning_body.kyck_id)
      ids.should include(team.kyck_id)
    end
  end

  describe '#plays_for' do
    let(:player) { create_player_for_organization(org1) }
    let(:other_user) { player.user }
    before do
      sign_in_user(regular_user)
    end

    it 'returns the plays_for for the user' do
      org1.open_team.official_roster.kyck_id
      User.any_instance.stub(:plays_for) {[org1.open_team.official_roster]}
      get :plays_for, id: other_user.kyck_id, format: :json
      ids = json.map { |o| o['id'] }
      ids.should include(org1.open_team.official_roster.kyck_id)
    end
  end

  # TODO: This is never called
  describe '#create', broken: true do
    let(:user_params) { valid_user_params }

    context 'when an admin user is logged in' do
      before(:each) do
        user = admin_user
        UserRepository.persist(user)
        sign_in_user(user)
        @obj = double
        KyckRegistrar::Actions::CreateAccount.stub(:new) {@obj}
      end

      it 'should create a new user' do
        assert_difference 'UserRepository.all.count' do
          @obj.stub(:execute) {{id: 1234}}
          post :create, user: user_params
        end
      end

      it 'should create a kyck account' do
        @obj.should_receive(:execute).and_return({id: 1234})
        post :create, user: user_params
      end

      [:first_name, :last_name, :email].each do |attr|
        context 'and the user does not supply a #{attr}' do

          it 'should show the error' do
            parms = user_params.tap {|p| p.delete(attr)}
            post :create, user: parms
            response.body.should have_selector('input#user_#{attr} + small', text:  'can\'t be blank')
          end
        end
      end

      it 'should allow permission_sets to be added to the user' do
        @obj.stub(:execute) {{id: 1234}}
        user_params[:permission_sets] = '[\'ManageStaff\', \'ManageMoney\']' # This is how the web client is submitting them
        post :create, user: user_params
        u = UserRepository.find_by_email(valid_user_params[:email]).first
        u.permission_sets.should == ['ManageStaff','ManageMoney']
      end

      it 'should handle empty permission_sets' do
        @obj.stub(:execute) {{id: 1234}}
        user_params[:permission_sets] = '' # This is how the web client is submitting them
        post :create, user: user_params
        u = UserRepository.find_by_email(valid_user_params[:email]).first
        u.permission_sets.should == []
      end
    end

    context 'when a user is not logged in'  do
      it 'should require a logged in user' do
        post :create, user: user_params
        response.should redirect_to(root_url)
      end
    end

    context 'when a non-admin user is logged in' do
      before(:each) do
        sign_in_user(regular_user)
      end

      it 'should redirect' do
        post :create, user: user_params
        response.should redirect_to root_url
      end
    end
  end

  describe '#index' do
    context 'when an admin is logged in' do
      before(:each) do
        @user = admin_user
        sign_in_user(@user)
        regular_user
      end

      context 'and query parameters are provided' do
        let!(:admin1) { admin_user }
        let!(:user2) { regular_user( last_name: 'Donkey')}

        before(:each) do
          regular_user
          regular_user
          Oriented.graph.commit
        end

        it 'should filter the users based on search text' do
          mock_execute_action(KyckRegistrar::Actions::GetUsers,
                              { conditions: {'last_name' => 'Donkey'},
                                limit: 25,
                                offset: 0},
                                [user2])
          get :index, filter: { last_name:'Donkey' }.to_json, format: :json
        end

        it 'should filter the users based on like search text' do
          mock_execute_action(KyckRegistrar::Actions::GetUsers,
                              { conditions: { 'last_name_like' => 'Don' },
                                limit: 25,
                                offset: 0},
                                [user2])
          get :index, filter: {last_name_like: 'Don'}.to_json, format: :json
        end

        it 'should filter the users based on kind' do
          get :index, filter:{kind: 'admin'}.to_json, format: :json
          json.count.should == 2 # The logged in user shows up too
          ids = json.map { |u| u['id'] }
          ids.should include admin1.kyck_id.to_s
        end
      end
    end

    context 'when a non-admin is logged in' do
      before(:each) do
        sign_in_user(regular_user)
      end

      it 'should redirect to root' do
        get :index
        response.should redirect_to root_url
      end
    end
  end

  describe '#edit' do
    before(:each) do
      @user = regular_user
    end

    context 'when an admin is logged in' do
      before(:each) do
        sign_in_user(admin_user)
      end

      it 'should assign the user' do
        get :edit, id: @user.kyck_id
        assigns(:user).should_not be_nil
      end
    end
  end

  describe '#update' do

    let(:user_params) { {first_name: 'Changed', last_name: 'Name', email:'new@email.com', middle_name: 'Billy'}}

    context 'when an admin user is logged in' do
      let(:requestor) {admin_user}

      before(:each) do
        sign_in_user(requestor)
        @mock =stub_wisper_publisher('KyckRegistrar::Actions::UpdateUser', :execute, :user_updated, requestor)
      end


      it 'should update a new user' do
        put :update, id: requestor.kyck_id, user: user_params
      end

      it 'should redirect to user' do
        put :update, id: requestor.kyck_id, user: user_params
        response.should redirect_to user_path(requestor)
      end
    end
  end
end

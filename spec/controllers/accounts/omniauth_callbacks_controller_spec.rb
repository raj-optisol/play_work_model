require 'spec_helper'

describe Accounts::OmniauthCallbacksController, type: :controller do

  describe "#kyck" do
    let(:the_user) { UserRepository.find_by_email('fred@flintstone.com')}
    let(:the_account) { Account.where(kyck_id: the_user.kyck_id).first}

    context "when a user record does not exist" do
      before(:each) do
        stub_env_for_kyck
      end

      it "should create the user record" do
        get :kyck
        the_user.should_not be_nil
      end

      it "should add a kyck token to the user" do
        get :kyck
        the_account.kyck_token.should_not be_nil
      end

      it "should add a first_name to the user" do
        get :kyck
        the_user.first_name.should_not be_blank
      end

      it "should add a last_name to the user" do
        get :kyck
        the_user.last_name.should_not be_blank
      end

      it "should set the user to claimed" do
        get :kyck
        the_user.claimed?.should be_true
      end

      context "when saving the user fails" do
        before(:each) do
          UserRepository.stub(:find_or_create_for_account).and_raise(StandardError)
          get :kyck
        end

        it "should redirect to root" do
          response.should redirect_to root_url
        end


        it "should have a message" do
          subject.flash[:error].should match(/Error logging in/)
        end
      end

    end

    context "when a user does exist" do
      before(:each) do
        stub_env_for_kyck
        @existing_user = Account.create!(email: 'test@test.com',kyck_id: '1234', kyck_token: nil)
        Account.stub(:find_for_omniauth_authentication).and_return(@existing_user)
      end

      it "should update the token" do
        get :kyck
        @existing_user.kyck_token.should == "123456789"
      end

      context "and the account kyck_id does not match the user kyck id" do
        let!(:the_user) {regular_user(email:'fred@flintstone.com')}
        before(:each) do
          stub_env_for_kyck
          @existing_user = Account.create!(email: 'fred@flintstone.com',kyck_id: '4567', kyck_token: nil)
          Account.stub(:find_for_omniauth_authentication).and_return(@existing_user)
        end

        it "fixes the user" do
          obj = double
          FixUserKyckId.stub(:new) { obj }
          obj.should_receive(:execute).with(kyck_id: @existing_user.kyck_id.to_s)
          get :kyck
        end
      end

      context "and the user is an admin" do
        before do
          stub_env_for_kyck
          stub_env_for_kyck_admin

          Oriented.graph.commit
        end
        it "should update the account to admin" do
          get :kyck
          Oriented.graph.commit
          UserRepository.find_by_email('test@test.com').admin?.should be_true
        end
      end
    end

    context "when a kyck admin signs in" do
        let!(:regular_user) {

          ud = FactoryGirl.create(:user, {email: 'fred@flintstone.com'})
          ud.save!
          UserRepository.find(ud.id)
        }
        before(:each) do
          stub_env_for_kyck
          stub_env_for_kyck_admin
          regular_user.kyck_id = request.env['omniauth.auth']['uid'].to_s
          regular_user._data.save
          Oriented.graph.commit
        end

        it "should make the account an admin account" do
          get :kyck
          regular_user._data.reload
          regular_user.admin?.should be_true
        end
    end
  end

  def stub_env_for_kyck
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:account]
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:kyck]
    @controller.stub(:env).and_return({"omniauth.auth" => OmniAuth.config.mock_auth[:kyck]})
  end

  def stub_env_for_kyck_admin
    OmniAuth.config.mock_auth[:kyck]["extra"]["raw_info"]["admin"] = true
  end
end

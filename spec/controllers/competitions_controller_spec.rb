require 'spec_helper'

describe CompetitionsController do
  include Devise::TestHelpers

  let(:requestor) { regular_user }
  let (:competition){ create_competition }

  before(:each) do
    sign_in_user(requestor)
  end

  describe "#create" do

    context "when a user has rights to manage competitions" do
      it "should call the create competition action" do
        mock_execute_action(KyckRegistrar::Actions::CreateCompetition, {"name" => "New Competition"}, competition)
        post :create, competition: {name: "New Competition"}
      end

      it "should redirect to the season competitions page" do
        stub_execute_action(KyckRegistrar::Actions::CreateCompetition, {"name" => "New Competition"}, competition)
        post :create, competition: {name: "New Competition"}
        response.should redirect_to competition_path(competition)
      end
    end

  end

  describe "#update" do
    context "when a user has the permission to manage competitions" do
      before(:each) do
        add_user_to_org(requestor, competition, {permission_sets: [PermissionSet::MANAGE_COMPETITION]})
      end

      it "calls the right action" do
        mock_execute_action(KyckRegistrar::Actions::UpdateCompetition, {"name" => "New Name"}, nil )
        put :update,  id: competition.kyck_id, competition: {"name" => "New Name"}
      end

    end
  end

  describe "#index" do
    context "when a user has rights to manage competitions" do
      before(:each) do
        add_user_to_org(requestor, competition, {permission_sets: [PermissionSet::MANAGE_COMPETITION]})
      end


      it "should show the competitions" do
        stub_execute_action(KyckRegistrar::Actions::GetCompetitions, nil, [competition])
        get :index, format: :json
        json[0]["id"].should == competition.id
      end

    end
  end

  describe "#destroy" do
    context "when the logged in user has manage competition rights" do
      before(:each) do
        add_user_to_org(requestor, competition, {permission_sets: [PermissionSet::MANAGE_COMPETITION]})
      end

      it "should call the delete action" do
        mock_execute_action(KyckRegistrar::Actions::RemoveCompetition)
        delete :destroy, id: competition.kyck_id
      end

      it "should redirect to the season's competition page" do
        stub_execute_action(KyckRegistrar::Actions::RemoveCompetition)
        delete :destroy, id: competition.kyck_id
        response.should redirect_to competitions_path
      end

      context "json"  do
        it "should respond right" do
          stub_execute_action(KyckRegistrar::Actions::RemoveCompetition)
          delete :destroy, id: competition.kyck_id.to_s, format: :json
          response.status.should == 204
        end
      end

    end
  end

  describe "#show" do
    context "when a user has rights to manage competitions" do
      before(:each) do
        add_user_to_org(requestor, competition, {permission_sets: [PermissionSet::MANAGE_COMPETITION]})
      end

      it "calls the action" do
        stub_execute_action(KyckRegistrar::Actions::GetCompetitions, nil, [competition])
        get :show, id: competition.kyck_id
      end
    end
  end
end

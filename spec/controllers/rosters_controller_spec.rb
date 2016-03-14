require 'spec_helper'
require 'wisper/rspec/stub_wisper_publisher'

describe RostersController do
  include Devise::TestHelpers
  let(:org) {
    create_club
  }
  let(:team) {
    create_team_for_organization(org)
  }

  let(:requestor) {regular_user}
  before do
    org.add_staff(requestor, {title:"Registrar", permission_sets:[PermissionSet::MANAGE_ROSTER]})
    OrganizationRepository.persist! org
    sign_in_user(requestor)
  end

  describe "#create" do

    context "when a user has rights to manage rosters" do
      before do
        stub_wisper_publisher("KyckRegistrar::Actions::CreateRotser", :execute, :roster_created, org)
      end

      it "calls the add roster action" do
        stub_wisper_publisher("KyckRegistrar::Actions::CreateRoster", :execute, :roster_created, org)
        post :create, team_id: team.kyck_id.to_s, roster: {name: "New Roster"}
      end

      it "redirect to the team rosters page" do
        stub_wisper_publisher("KyckRegistrar::Actions::CreateRoster", :execute, :roster_created, org)
        post :create, team_id: team.kyck_id.to_s, roster: {name: "New Roster"}
        response.should redirect_to team_rosters_path(team)
      end
    end

  end

  describe "#index" do
    context "when a user has rights to manage rosters" do

      let!(:existing_roster) {
        ros = team.create_roster({name: 'A Roster'})
        OrganizationRepository::TeamRepository.persist! team
        ros
      }

      it "calls GetRosters" do
        mock_execute_action(KyckRegistrar::Actions::GetRosters, nil, [existing_roster])
        get :index, team_id: team.kyck_id.to_s, format: :json
      end
    end
  end

  describe "#destroy" do
    context "when the logged in user has manage roster rights" do

      let!(:existing_roster) {
        ros = team.create_roster({name: 'A Roster'})

        ros = TeamRepository::RosterRepository.persist! ros
        ros
      }

      it "should call the delete action" do
        @mock = double
        KyckRegistrar::Actions::RemoveRoster.stub!(:new) { @mock }
        @mock.should_receive(:execute).with()
        delete :destroy, team_id: team.kyck_id, id: existing_roster.kyck_id.to_s
      end

      it "should redirect to the team's roster page" do
        @mock = double
        KyckRegistrar::Actions::RemoveRoster.stub!(:new) { @mock }
        @mock.stub(:execute).with(any_args())
        delete :destroy, team_id: team.kyck_id, id: existing_roster.kyck_id.to_s
        response.should redirect_to team_rosters_path(team)
      end

      context "json"  do
        it "should respond right" do
          @mock = double
          KyckRegistrar::Actions::RemoveRoster.stub!(:new) { @mock }
          @mock.stub(:execute).with(any_args())
          delete :destroy, team_id: team.kyck_id.to_s, id: existing_roster.kyck_id.to_s, format: :json
          response.status.should == 204
        end
      end

    end
  end

  describe "#show" do
    context "when a user has rights to manage rosters" do

      let!(:player) {
        regular_user
      }

      let!(:existing_roster) {
        ros = team.create_roster({name: 'A Roster'})
        TeamRepository::RosterRepository.persist! ros
        ros.add_player(player,{})
        TeamRepository::RosterRepository.persist! ros
        ros
      }

      context "and json is requested" do
        it "includes the players" do
          get :show, team_id: team.kyck_id.to_s, id: existing_roster.kyck_id, format: :json
          json["players"].count.should == 1
        end
      end

    end

  end
end

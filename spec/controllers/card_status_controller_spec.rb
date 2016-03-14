require 'spec_helper'

describe CardStatusController do
  include Devise::TestHelpers
  let(:uscs) {create_sanctioning_body({name: 'USCS'})}
  let(:requestor) {regular_user}
  let(:club) {create_club}

  before do
    sign_in_user(requestor)
  end

  describe "#index" do
    context "for an organization" do
      context "when the current user has permissions" do
        before do
          add_user_to_org(requestor, club, permission_sets: [PermissionSet::REQUEST_PLAYER_CARD])
          stub_execute_action(KyckRegistrar::Actions::GetUncarded, {limit: 25, offset: 0}, [])
        end
        context "when the organization is sanctioned" do
          before  do
            create_sanctioning_request(uscs, club, requestor, {status: :approved } )
          end

          it "is successfull" do
            get :index, organization_id: club.kyck_id, format: :json
            response.should be_successful
          end

        end
      end
    end

    context "for an organization" do
      context "when the current user has permission" do
        let(:team) {create_team_for_organization(club)}
        let(:roster) {create_roster_for_team(team)}
        let(:player) { add_player_to_roster(roster)}
        let(:player2) {add_player_to_roster(roster)}
        let(:card) {uscs.card_user_for_organization(player.user, club)}
        let(:card2) {uscs.card_user_for_organization(player2.user, club)}
        let(:card_status) { CardStatus.new(player.user )}

        before do
          add_user_to_org(requestor, club, permission_sets: [PermissionSet::REQUEST_PLAYER_CARD])
          stub_execute_action(KyckRegistrar::Actions::GetOrCreateOrder, {create_order: false, payer_id: club.kyck_id}, Order.new)
        end

        it "returns the carded players" do
          stub_execute_action(KyckRegistrar::Actions::GetUncarded, {limit: 25, offset: 0}, [card_status])
          get :index, format: :json, organization_id: club.kyck_id
          json[0]["user"]["id"].should == player.user.kyck_id
        end

        context "when filtering" do

          context "by last name" do

            it "filters the returned items" do
              mock_execute_action(KyckRegistrar::Actions::GetUncarded, {limit: 25, offset: 0,user_conditions: {last_name_like: player.user.last_name}}, [card_status])
              get :index, format: :json, organization_id: club.kyck_id, filter: {"last_name_like"  => player.user.last_name}
            end

          end

        end

      end

    end
  end
end

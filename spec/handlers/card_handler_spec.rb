require 'spec_helper'

describe CardHandler do

  describe "when note added to card" do
    let(:requestor) {regular_user}
    let(:sb) {create_sanctioning_body}
    let(:org) {create_club}
    let(:team) {create_team_for_organization(org)}
    let(:carded_user) {regular_user}
    let(:card) {create_card(carded_user, team, sb, status: :requested)}

    subject { CardHandler.new }

    context "and requestor is staff for SB" do
      before do
        add_user_to_org(requestor, sb, permission_sets: [PermissionSet::MANAGE_CARD])
      end
      it "sets the card status " do
        res = subject.note_added_to_card(requestor, card)
        card.message_status.should == :requestor_response_required
      end
    end

    context "and requestor is staff for Organization" do
      before do
        add_user_to_org(requestor, org, permission_sets: [PermissionSet::MANAGE_CARD])
      end
      it "sets the card status " do
        res = subject.note_added_to_card(requestor, card)
        card.message_status.should == :requestor_response_received
      end
    end

    it "doesn't change the card status for user without permissions " do
      res = subject.note_added_to_card(requestor, card)
      card.message_status.should == :read
    end

  end # END NOTE ADDED TO CARD
end

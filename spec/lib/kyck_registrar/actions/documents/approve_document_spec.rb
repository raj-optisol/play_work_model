require 'spec_helper'

module KyckRegistrar
  module Actions
    describe ApproveDocument do

      describe "#execute" do

        let(:requestor) {regular_user}

        let(:uscs) { create_sanctioning_body}
        let(:club) {create_club}
        let(:card) { create_card(requestor, club, uscs)}
        let(:doc) {create_document_for_user(requestor, status: :not_reviewed)}

        subject {described_class.new(requestor, doc, card).execute}
        context "when the requestor has permissions" do

          before do
            add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
          end

          it "adds the doc to card documents" do
            expect {subject}.to change {card.documents.count}.by(1)
          end

        end

        context "when the requestor does not have permissions" do

          it "raises a permissions error" do
            expect {subject}.to raise_error PermissionsError 
          end
        end
      end
    end
  end
end

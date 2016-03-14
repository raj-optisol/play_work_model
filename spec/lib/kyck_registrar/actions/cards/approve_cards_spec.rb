require 'spec_helper'

module KyckRegistrar
  module Actions
    describe ApproveCards do
      let(:requestor) {regular_user}
      let(:uscs) {create_sanctioning_body}
      let(:team) {create_team}
      let(:carded_user) {regular_user}
      let(:order) {create_order(requestor, team, uscs, kind: :card_request)}
      let(:card) {create_card(carded_user, team, uscs, status: :requested)}

      describe "#execute" do
        subject {described_class.new(requestor, uscs)}

        context "when the user has permissions" do
          before do
            add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
          end

          it "approves the card" do
            card.status.should == :requested
            card_executed = subject.execute(card_ids: [card.kyck_id]) .first
            card._data.reload
            card_executed.status.should == :approved
          end

          it "sets the approved on date" do
            card.approved_on = nil
            card._data.save
            card_executed = subject.execute(card_ids: [card.kyck_id]) .first
            card._data.reload
            card_executed.approved_on.should_not be_nil
          end

          context "when the card has a non-read message status" do
            before do
              card.message_status = :requestor_response_received
              card._data.save
            end

            it "sets the message status to read" do
              card.message_status.should == :requestor_response_received
              card_executed = subject.execute(card_ids: [card.kyck_id]).first
              card_executed.message_status.should == :read
            end
          end

          context "when the user has docs" do

            let(:doc_action) {Object.new}
            let!(:waiver) { create_document_for_user(carded_user, {kind: :waiver})}
            before do
              doc_action.should_receive(:execute)
              subject.document_action = doc_action
            end

            it "approves the documents" do
              subject.execute(card_ids: [card.kyck_id])
            end
          end

          context 'for a competition' do
            let(:comp) { create_competition }

            before do
              card._data.processor = comp._data
              CardRepository.persist card
            end

            context 'when the user does NOT have permission' do
              let(:league_admin) { regular_user }
              before { add_user_to_org(league_admin, comp) }
              subject { described_class.new(league_admin, uscs, comp) }

              it 'raises a permission error' do
                comp.stub(:can_process_cards_for_sb?) { true }
                expect { subject.execute(card_ids: [card.kyck_id]) }
                  .to raise_error
              end
            end

            context 'when the user has permissions' do
              let(:league_admin) { regular_user }

              before do
                add_user_to_org(
                  league_admin,
                  comp,
                  permission_sets: [PermissionSet::MANAGE_CARD]
                )
              end

              subject { described_class.new(league_admin, uscs, comp) }

              context 'when the competition can process cards' do
                it 'approves the cards' do
                  comp.stub(:can_process_cards_for_sb?) { true }
                  card_ex = subject.execute(card_ids: [card.kyck_id]).first

                  expect(card_ex.status).to eq(:approved)
                end
              end

              context 'when the competition cannot process cards' do
                it 'raises a permission error' do
                  comp.stub(:can_process_cards_for_sb?) { false }
                  expect { subject.execute(card_ids: [card.kyck_id]) }
                    .to raise_error
                end
              end
            end
          end
        end

        context "when the user is not permitted to approve cards" do

          it "throws a permissions error" do
            expect {subject.execute(card_ids: [card.kyck_id])}.to raise_error PermissionsError
          end

        end
      end
    end
  end
end

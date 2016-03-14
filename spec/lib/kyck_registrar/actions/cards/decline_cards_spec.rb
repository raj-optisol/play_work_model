require 'spec_helper'

module KyckRegistrar
  module Actions
    describe DeclineCards do
      let(:requestor) {regular_user}
      let(:uscs) {create_sanctioning_body}
      let(:team) {create_team}
      let(:carded_user) {regular_user}
      let(:card) {create_card(carded_user, team, uscs, status: :requested)}

      describe "#execute" do
        subject {described_class.new(requestor, uscs)}

        context "when the user has permissions" do
          before do
            add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
          end

          it "declines the card" do
            subject.execute(card_ids: [card.kyck_id], reason: "Because we don't like you")
            card._data.reload
            card.status.should == :denied
          end

          it "adds a note to the card" do
            subject.execute(card_ids: [card.kyck_id], reason: "Because we don't like you")
            card._data.reload
            card.notes.first.text.should =~ /Because/
          end

          it "broadcasts the decline" do
            listener = double("listener")
            listener.should_receive(:cards_declined).with instance_of Array
            subject.subscribe(listener)
            subject.execute(card_ids: [card.kyck_id], reason: "Because we don't like you")

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
                it 'declines the cards' do
                  comp.stub(:can_process_cards_for_sb?) { true }
                  card_ex = subject.execute(card_ids: [card.kyck_id]).first

                  expect(card_ex.status).to eq(:denied)
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

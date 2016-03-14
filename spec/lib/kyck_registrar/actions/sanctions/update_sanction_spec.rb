require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateSanction do

      describe "#execute" do
        let(:requestor) { regular_user }
        let(:uscs) { create_sanctioning_body }
        let(:club) { create_club }
        let(:sanction) { create_sanction_for_sb_and_item(uscs, club) }

        subject { described_class.new(requestor, sanction) }

        context "when the user has permissions" do

          before do
            add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_ORGANIZATION] )
          end

          it "updates the sanction" do
            result = subject.execute(status: :inactive)
            result.status.should == :inactive
          end

          context "for a competition" do
            let(:comp) { create_competition }
            let(:sanction) { create_sanction_for_sb_and_item(uscs, comp) }

            it "updates the sanction" do
              result = subject.execute(status: :inactive, can_process_cards: true)
              result.status.should == :inactive
              result.can_process_cards.should == true
            end
          end
        end
        context "when the user has permissions" do
          it "raises a permissions error" do
            expect { subject.execute(status: :inactive) }.to raise_error PermissionsError
          end
        end

      end
    end
  end
end

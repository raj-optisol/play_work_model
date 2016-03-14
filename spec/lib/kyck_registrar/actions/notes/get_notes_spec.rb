require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetNotes do

      describe "#execute" do
        let(:requestor) {regular_user}
        let(:uscs) {create_sanctioning_body}
        let(:club) {create_club}

        context "for a sanctioning_request" do

          let(:sr) { create_sanctioning_request(uscs, club, requestor ) }
          let!(:note) { create_note_for_target(sr)  }
          subject { described_class.new(requestor, sr)}

          context "when the requestor has permission" do

            subject { described_class.new(requestor, sr)}

            before do
              add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_REQUEST])
            end

            it "returns the notes" do
              notes= subject.execute()
              notes.count.should == 1
            end
          end
        end


        describe "for a competition entry" do
          let(:comp) { create_competition } 
          let(:division) { create_division_for_competition(comp)} 
          let(:team) { create_team} 
          let!(:note) { create_note_for_target(entry)  }
          let(:entry) { create_competition_entry(requestor, comp, division,team, nil) }
          let(:uscs_admin) {regular_user}
          subject { described_class.new(uscs_admin, entry)}

          before do
            create_sanction_for_sb_and_item(uscs, comp)
            add_user_to_org(uscs_admin, uscs, permission_sets: [PermissionSet::MANAGE_ORGANIZATION])
          end

          it "returns the notes" do
            notes= subject.execute()
            notes.count.should == 1
          end

        end
      end
    end
  end
end

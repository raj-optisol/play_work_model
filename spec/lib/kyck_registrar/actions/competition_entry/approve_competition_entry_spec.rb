require 'spec_helper'

module KyckRegistrar
  module Actions
    describe ApproveCompetitionEntry do
      let(:requestor) { regular_user}
  
      let(:team) {create_team}
      let(:roster) { create_roster_for_team(team) }        
      
      let(:competition) { create_competition }
      let(:division) { create_division_for_competition(competition) }
      
      let(:competition_entry) { create_competition_entry(requestor, competition, division, team, roster ) }
      

      describe "initialize" do
        it "takes a requestor and a competition entry" do
          expect {described_class.new(regular_user, competition_entry)}.to_not raise_error
        end
      end

      describe "#execute" do

        let(:input) { { kyck_id: competition_entry.kyck_id } }

        subject{described_class.new(requestor, competition_entry)}

        context "when the requestor has permission" do
          before(:each) do
            add_user_to_org(requestor, competition, {title: 'Admin',permission_sets: [PermissionSet::MANAGE_REQUEST] })

          end

          it "approves the competition entry" do
            sa = subject.execute(input)
            sa.status.should == :approved
          end

          it "publishes approval event" do
            listener = double('listener')
            listener.should_receive(:competition_entry_approved).with instance_of CompetitionEntry
            subject.subscribe(listener)
          
            subject.execute(input)
          end


        end

        context "when the requestor does not have permission" do
        
          it "raises an error" do
            expect {subject.execute(input)}.to raise_error PermissionsError
          end
        
        end
      end
    end
  end
end

require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateCompetitionEntry do
      let(:requestor) { regular_user}
  
      let(:team) {create_team}
      let(:roster) { create_roster_for_team(team) }   
      let(:roster2) { create_roster_for_team(team) }              
      
      let(:competition) { create_competition }
      let(:division) { create_division_for_competition(competition) }
      let(:division2) { create_division_for_competition(competition) }
            
      let(:competition_entry) { create_competition_entry(requestor, competition, division, team, roster ) }
      

      describe "initialize" do
        it "takes a requestor and a competition entry" do
          expect {described_class.new(regular_user, competition_entry)}.to_not raise_error
        end
      end

      describe "#execute" do

        let(:input) { { status: :approved } }

        subject{described_class.new(requestor, competition_entry)}

        context "when the requestor has permission" do
          before(:each) do
            add_user_to_org(requestor, competition, {title: 'Admin',permission_sets: [PermissionSet::MANAGE_REQUEST] })

          end

          it "approves the competition entry" do
            sa = subject.execute(input)
            sa.status.should == :approved
          end

          it "updates the entry division" do
            inp = {division_id:division2.kyck_id}
            entry = subject.execute(inp)
            competition_entry.division.kyck_id.should == division2.kyck_id
          end
          
          it "updates the entry roster" do
            inp = {roster_id:roster2.kyck_id}
            entry = subject.execute(inp)
            competition_entry.roster.kyck_id.should == roster2.kyck_id
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

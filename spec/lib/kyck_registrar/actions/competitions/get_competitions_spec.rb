require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetCompetitions do

      subject { KyckRegistrar::Actions::GetCompetitions }

      it "requires a requestor" do
        expect { subject.new }.to raise_error ArgumentError
      end

      describe "#execute" do
        let(:comp) { create_competition(name: "The Comp 1", start_date:DateTime.now, end_date:(DateTime.now+6.months)) }

        context "for TEAM" do
          let(:requestor) { regular_user }
          let(:org) { create_club }
          let(:team) { create_team_for_organization(org) }
          let(:roster) { create_roster_for_team(team) }
          let(:division) { create_division_for_competition(comp) }
          let(:comp2) { create_competition(name: "League 1", start_date:DateTime.now, end_date:(DateTime.now+6.months)) }
          let!(:div2) { create_division_for_competition(comp2) }

          before(:each) do
            comp.add_staff(requestor, title:"Coach", permission_sets: [PermissionSet::MANAGE_COMPETITION])
            CompetitionRepository.persist comp
          end

          it "returns the competitions the team can join" do
            action = subject.new(requestor, team)
            comps = action.execute(available: true)
            comps.count.should == 2
          end
        end
      end
    end
  end
end

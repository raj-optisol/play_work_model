require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UnlockRostersForDivision, broken: true do

      describe "#new" do
        it 'takes a requestor and a division' do
          expect {described_class.new}.to raise_error ArgumentError
          expect {described_class.new(User.new)}.to raise_error ArgumentError
          expect {described_class.new(User.new, Division.new)}.to_not raise_error ArgumentError
        end
      end

      describe "#execute" do
        let (:team) { create_team }
        let (:roster) { create_roster_for_team(team) }
        let (:comp) { create_competition }
        let (:div) { create_division_for_competition(comp) }



        context 'when requestor has permission' do
          let(:requestor) {
            u = regular_user
            comp.add_staff(u, {title:'Dood', permission_sets:[PermissionSet::MANAGE_COMPETITION]})
            UserRepository.persist u
            u
          }

          it 'unlocks all the rosters' do
            div.add_roster(roster)
            CompetitionRepository::DivisionRepository.persist div
            action = described_class.new(requestor, div)
            action.execute
            div.rosters.first.locked.should == false
          end
        end

        context 'when requestor does not have permission' do
          let(:requestor) { regular_user }

          it 'raises an error' do
            action = described_class.new(requestor, div)
            expect{action.execute}.to raise_error PermissionsError
          end
        end
      end
    end#end test
  end
end


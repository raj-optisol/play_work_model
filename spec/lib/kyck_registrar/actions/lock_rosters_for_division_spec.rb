require 'spec_helper'

module KyckRegistrar
  module Actions
    describe LockRostersForDivision, broken:true do
      describe "#new" do
        it 'takes a requestor and a division, and optionally an array of teams' do
          expect {described_class.new}.to raise_error ArgumentError
          expect {described_class.new(User.new)}.to raise_error ArgumentError
          expect {described_class.new(User.new, Division.new)}.to_not raise_error ArgumentError

          team_array = []
          5.times { team_array << FactoryGirl.build(:team) }
          expect {described_class.new(User.new, Division.new, team_array)}.
            to_not raise_error ArgumentError
        end
      end

      describe "execute" do
        before(:each) do
          @team = create_team
          @roster = create_roster_for_team(@team)
          @comp = create_competition
          @div = create_division_for_competition(@comp)
          @div.add_roster(@roster)
          CompetitionRepository::DivisionRepository.persist @div
        end

        context 'when requestor has permission' do
          let(:requestor) {
            u = regular_user
            @comp.add_staff(u, {title:'Dood', permission_sets:[PermissionSet::MANAGE_COMPETITION]})
            UserRepository.persist u
            u
          }

          it 'locks all the rosters' do
            action = described_class.new(requestor, @div)
            action.execute
            @div.rosters.first.locked.should == true
          end
        end
        context 'when requestor does not have permission' do
          let(:requestor) { regular_user }

          it 'raises an error' do
            action = described_class.new(requestor, @div)
            expect{action.execute}.to raise_error PermissionsError
          end
        end
      end
    end
  end
end


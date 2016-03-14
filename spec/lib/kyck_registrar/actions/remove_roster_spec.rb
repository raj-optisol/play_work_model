require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveRoster do

      subject{KyckRegistrar::Actions::RemoveRoster}

      describe "#new" do
        it "should take a requestor" do
          expect{subject.new}.to raise_error ArgumentError
        end

        it "should take a roster" do
          expect{subject.new(User.new)}.to raise_error ArgumentError
        end

        it "should take a roster" do
          expect{subject.new(User.new, Roster.new)}.to_not raise_error ArgumentError
        end
      end

      describe "#execute" do

        before(:each) do
          @org = create_club

          @team = @org.create_team(name: 'New Team')
          OrganizationRepository.persist @org

          @roster = @team.create_roster({name: 'A Roster'})
          OrganizationRepository::TeamRepository.persist! @team
        end

        context "when the requestor has permission to delete the roster" do

          let(:requestor) {
            u = regular_user
            @org.add_staff(u, {title:"Dood", permission_sets:[PermissionSet::MANAGE_ROSTER]})
            UserRepository.persist(u)
            u
          }

          it "should tell the repo to remove the team" do
            mock = double
            mock.should_receive(:delete_by_id).with(@roster.id)

            action = subject.new(requestor, @roster)
            action.repository = mock

            action.execute()
          end

          it "should raise a cant delete error when roster is official" do
            officialRoster = @team.create_roster(name:"Official Roster", official:true)
            OrganizationRepository::TeamRepository.persist @team

            action = subject.new(requestor, officialRoster)

            expect{action.execute()}.to raise_error CantDeleteError
          end
        end

        context "when the requestor does not have permission to delete the roster" do
          let(:requestor) { regular_user }

          it "should raise an error" do
            action = subject.new(requestor, @roster)

            expect{action.execute()}.to raise_error PermissionsError
          end
        end
      end
    end
  end
end

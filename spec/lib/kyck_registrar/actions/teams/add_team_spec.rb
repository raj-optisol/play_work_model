require 'spec_helper'
module KyckRegistrar
  module Actions
    describe AddTeam do
      let(:requestor) {regular_user}
      let(:organization) {create_club}
      describe "#initialize" do
        it "takes a requestor and a organization" do
          action = AddTeam.new(requestor, organization)
        end
      end

      describe "#execute" do
        let(:team) {create_team}
        before(:each) do
          organization.add_staff(requestor, {permission_sets:[PermissionSet::MANAGE_TEAM]})
          UserRepository.persist requestor
          @subject = AddTeam.new(requestor, organization)
        end

        it "adds the team to the organization" do
          expect {
            @subject.execute(team)
          }.to change {organization.teams.count}.by(1)

        end
      end
    end
  end
end

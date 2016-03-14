require 'spec_helper'
require_relative '../../../../lib/kyck_registrar/actions/get_rosters'
require_relative '../repositories/team_memory_repository'
require_relative '../repositories/organization_memory_repository'

module KyckRegistrar
  module Actions
    describe GetRosters do

      let(:club) { create_club}
      let(:requestor) {regular_user}
      describe ".new" do
        it "should require a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "should require a team" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        context "for a team" do
          let!(:team) {create_team_for_organization(club) }
          let!(:existing_roster) { create_roster_for_team(team) }
          subject { described_class.new(requestor, team) }

          context "when a user has rights to view rosters" do
            before do
              add_user_to_org(requestor, club, permission_sets: [PermissionSet::MANAGE_ROSTER])
            end

            it "should return the rosters" do
              existing_roster._data.__java_obj.load
              rosters = subject.execute
              rosters.map(&:name).should include(existing_roster.name)
            end
          end

          context "when a user does not have rights to view rosters" do

            it "should raise an error" do
              expect{subject.execute}.to raise_error PermissionsError
            end
          end
        end

        context "for a division", broken: true do
          let(:requestor) {regular_user}
          let(:competition) {create_competition}
          let(:division) { create_division_for_competition(competition) }
          let!(:existing_roster) { create_roster_for_division(division) }

          subject {described_class.new(requestor, division)}

          context "when the user is part of the competition" do

            before do
              add_user_to_org(requestor, competition, permission_sets: [PermissionSet::MANAGE_ROSTER])
            end

            it "returns the rosters for the division" do
              rosters = subject.execute
              rosters.map(&:name).should include(existing_roster.name)
            end
          end

          context "when the user is part of the competition" do

            before do
              add_user_to_org(requestor, competition, permission_sets: [PermissionSet::MANAGE_COMPETITION])
            end

            it "returns the rosters for the division" do
              rosters = subject.execute
              rosters.map(&:name).should include(existing_roster.name)
            end
          end
        end
      end
    end
  end
end

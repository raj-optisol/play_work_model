require 'spec_helper'
require 'smarter_csv'

module KyckRegistrar
  module Import
    describe "Importing test staff file" do
      let(:requestor) { regular_user} 
      let(:club) {create_club}
      let(:csv) {SmarterCSV.process("#{Rails.root}/spec/support/import_staff.csv")}
      let(:processor) {
        p = KyckRegistrar::Import::ImportCSV.new(club, requestor, csv) 
        p.reporter = DevNullReporter.new
        p
      }

      subject{
        processor.execute
        Oriented.graph.commit
      }
      context "when the requestor has MANAGE_ORGANIZATION" do
        before do
          st = club.add_staff(requestor, {permission_sets: [PermissionSet::MANAGE_ORGANIZATION]})
          OrganizationRepository.persist! club 
        end

        it "creates the U-14 Boys team" do
          subject
          OrganizationRepository::TeamRepository.get_teams_for_organization(club, conditions: {name: 'U-14 Boys Tigers'}).first.should_not be_nil
        end


        context "when a team name is not supplied" do
          it "creates a user" do
            subject
            UserRepository.find_by_email("admin@guy.com").should_not be_nil
          end

          it "adds the user to the organization" do
            subject
            u = UserRepository.find_by_email("admin@guy.com")
            u.staff_for.map(&:kyck_id).should include club.kyck_id
          end

          it "adds the user with the right privs" do
            subject
            u = UserRepository.find_by_email("admin@guy.com")
            (u.get_staff_relationships.first.permission_sets.to_a & ["MANAGE_TEAM", "MANAGE_CARD", "MANAGE_REQUEST"]).count.should == 3   
          end
        end

        context "when a team name is supplied" do
        
          it "adds the user to the team" do
            subject
            u = UserRepository.find_by_email("coach@guy.com")
            u.staff_for.map(&:name).should include "U-14 Boys Tigers"

          end

          it "creates the users with the right staff attributes" do
            subject
            u = UserRepository.find_by_email("coach@guy.com")
            u.get_staff_relationships.first.title == "Coach"
          end

        end

        context "when no permission sets are supplied" do
        
          it "creates the user" do
            subject
            UserRepository.find_by_email("s@intown.com").should_not be_nil
          end

        end
      end

    end
  end
end

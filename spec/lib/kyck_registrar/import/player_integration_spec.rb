require 'spec_helper'
require 'smarter_csv'

module KyckRegistrar
  module Import
    describe "Importing test players file" do
      let(:requestor) { regular_user }
      let(:club) {create_club}
      let(:csv) {SmarterCSV.process("#{Rails.root}/spec/support/import_players.csv")}

      subject{
        p = KyckRegistrar::Import::ImportCSV.new(club, requestor, csv)
        p.reporter = DevNullReporter.new
        p.execute
      }
      context "when the requestor has MANAGE_ORGANIZATION" do
        before do
          st = club.add_staff(requestor, {permission_sets: [PermissionSet::MANAGE_ORGANIZATION]})
          OrganizationRepository.persist club
        end

        it "creates the U-14 Boys team" do
          subject
          OrganizationRepository::TeamRepository.get_teams_for_organization(club, conditions: {name: 'U-14 Boys Tigers'}).first.should_not be_nil
        end

        context "when a parent email is supplied but a player email is not" do
          it "creates a parent user" do
            subject
            UserRepository.find_by_email("new@intown.com").should_not be_nil
          end

          it "creates a sub user for the player user to the parent" do
            subject
            parent = UserRepository.find_by_email("new@intown.com")
            parent.accounts.first.full_name.should == "Johnny Comelately"
          end

        end

        context "when a player email and a parent email are both supplied" do

          it "creates a parent user" do
            subject
            UserRepository.find_by_email("parent_b@intown.com").should_not be_nil
          end

          it "creates a player user" do
            subject
            UserRepository.find_by_email("b@intown.com").should_not be_nil
          end

          it "creates a sub user for the player user to the parent" do
            subject
            parent = UserRepository.find_by_email("parent_b@intown.com")
            parent.accounts.first.full_name.should == "Jim Comelately"
          end

          it "adds the player to the club" do
            subject
            OrganizationRepository::PlayerRepository.for_organization(club, conditions:{user_condtions: {first_name: 'Jim', last_name: 'Comelately'}}).first.should_not be_nil
          end

          it "adds the player to the official roster of the team" do
            subject
            t = club.teams.first
            t.official_roster.players.select {|p| p.first_name=='Jim' && p.last_name=='Comelately'}.first.should_not be_nil
          end
        end

        context "when a player email is only supplied" do
          it "creates a player user" do
            subject
            UserRepository.find_by_email("g@intown.com").should_not be_nil
          end
        end
      end
    end
  end
end

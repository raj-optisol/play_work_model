require 'spec_helper'
require_relative '../../app/repositories/competition_repository'

describe CompetitionRepository do
  describe "get_card_processing_compeititons" do
    let(:org) {create_club}
    let(:season) {create_season_for_organization(org)}
    let(:sb) {create_sanctioning_body}

    before :each do
      @processing_comp = create_competition
      create_sanction_for_sb_and_item(sb, @processing_comp, :can_process_cards => true)
      @non_processing_comp = create_competition
      create_sanction_for_sb_and_item(sb, @processing_comp)
      @unsanctioned_comp = create_competition
      @competitions = CompetitionRepository.get_card_processing_competitions
    end

    it "should return any competitions with sanctions permitting them to process cards" do
      expect(@competitions.map(&:kyck_id)).to include(@processing_comp.kyck_id)
    end

    it "should not return any competitions with santions not permitting them to process cards" do
      expect(@competitions.map(&:kyck_id)).not_to include(@non_processing_comp.kyck_id)
    end

    it "should not return any unsanctioned competitions" do
      expect(@competitions.map(&:kyck_id)).not_to include(@unsanctioned_comp.kyck_id)
    end
  end

  describe "removing team from competition" do
    before(:each) do
      @org = create_club

      @team = Team.build(name: 'New Team')
      @org.add_team(@team)
      OrganizationRepository.persist @org

      @roster = @team.create_roster({name: 'A Roster'})
      OrganizationRepository::TeamRepository.persist @team

      @comp = @org.create_competition(name: "The Comp 1", start_date:DateTime.now, end_date:(DateTime.now+6.months))
      CompetitionRepository.persist @comp

      @division = @comp.create_division({name: "Division One", age: "18", gender:"male", kind:"premier"})
      CompetitionRepository::DivisionRepository.persist @division

      @division.add_roster(@roster)
      CompetitionRepository::DivisionRepository.persist @division
    end
  end
end

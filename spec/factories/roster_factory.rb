require 'factory_girl'

FactoryGirl.define do
  sequence(:roster_name) {|n| "Roster#{n}"}

  factory :roster, class: RosterData do
    name {FactoryGirl.generate :roster_name}
    kyck_id { UUIDTools::UUID.random_create.to_s}
    team {FactoryGirl.create(:team)}
  end
end

def create_roster_for_team(team, props={}, repo = TeamRepository::RosterRepository)
  roster= FactoryGirl.build(:roster)
  rprops = roster.props.slice("name")
  roster = team.create_roster(rprops.merge(props))
  repo.persist! roster 
  repo.find(roster.id)
end

def create_roster_for_division(division, repo = TeamRepository::RosterRepository)
  roster= FactoryGirl.create(:roster)
  roster = repo.find(roster.id)
  roster = division.add_roster(roster)
  roster
end

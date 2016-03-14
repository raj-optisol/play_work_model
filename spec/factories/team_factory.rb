require 'factory_girl'

FactoryGirl.define do
  sequence(:team_name) {|n| "Team#{n}"}

  factory :team, class: TeamData do
    name {FactoryGirl.generate :team_name}
    gender :male
    player_count 12
    kyck_id { UUIDTools::UUID.random_create.to_s}
    born_after { Date.today - 10.years }
		avatar 'default_avatar'

    trait :female do
      gender "F"
    end

    trait :with_org do
      organization {FactoryGirl.create(:club)}
    end

  end
end

def create_team_for_organization(club, attrs={}, repo = OrganizationRepository::TeamRepository)
  default_attrs = FactoryGirl.build(:team).props
  newattrs = default_attrs.slice!("id", "created_at", "updated_at", "kyck_id", "avatar").merge(attrs)
  team = club.create_team(newattrs)
  repo.persist! team
  team
end

def create_team(attrs={})
  team = FactoryGirl.create(:team)
  team.save!
  team = OrganizationRepository::TeamRepository.find(team.id)

end

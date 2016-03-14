require 'factory_girl'

FactoryGirl.define do

  factory :player, class: PlayerData do
    user  {FactoryGirl.create(:user)}
    gender 'M'
    position 'Forward'
    kyck_id { UUIDTools::UUID.random_create.to_s}
  end
end

def create_player_for_organization(club, repo = OrganizationRepository)
  user = regular_user
  player = club.add_player(user )
  UserRepository.persist user
  player
end

def add_player_to_roster(roster, user_attrs={}, player_attrs={})
  player = FactoryGirl.create(:user, user_attrs)
  user = UserRepository.find(player.id.to_s)
  p = roster.add_player(user, player_attrs)
  UserRepository.persist user
  p
end

def add_user_to_roster(roster, user, player_attrs={})
  p = roster.add_player(user, player_attrs)
  UserRepository.persist user
  p
end

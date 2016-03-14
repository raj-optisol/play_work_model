# encoding: UTF-8

# This model is used to declare site-wide features that can later be turned ON
# or OFF dynamically without bringing the site down.

# TODO: ensure features can be independent from the fron-end of the system.
# Meaning that if we decide to change the template system we can do so easily.
class Feature < ActiveRecord::Base
  extend Flip::Declarable

  strategy Flip::CookieStrategy
  strategy Flip::DatabaseStrategy
  strategy Flip::DeclarationStrategy
  default proc { !Rails.env.production? }

  # Declare your features here, e.g:
  #
  # feature :world_domination,
  #   default: true,
  #   description: "Take over the world."

  feature :release_players
  feature :remove_players
  feature :remove_staff
  feature :remove_teams
  feature :update_kyck_account_attributes,
          description: 'Updates KYCK Account info when user is updated'
  feature :remove_rosters
  feature :fix_user_kyck_id,
          description: 'Fixing the non-matching KYCK ID from KYCK Account'
  feature :cache_org,
          default: true,
          description: 'Caching for Organization Overview'
  feature :cache_user,
          default: true,
          description: 'Caching for Profile'
  feature :cache_card,
          default: true,
          description: 'Caching for Card'

  feature :cache_views,
          description: 'Cache basic views',
          default: true
end

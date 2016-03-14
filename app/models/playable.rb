module Playable

  module Model
    def get_players(filters={})
      OrganizationRepository::PlayerRepository.get_players(self, filters)
    end

    def get_player_for_user(user)
      st = _data.get_player_for_user(user)
      wrap st
    end

    def get_player_by_kyck_id(player_kyck_id)
      wrap _data.get_player_by_kyck_id(player_kyck_id)
    end

    def add_player(user, attrs = {})
      wrap _data.add_player(user, attrs)
    end

  end

  module Data

    def add_player(user, attrs={})
      rel = get_player_for_user(user)
      return rel if rel
      user._data.plays_for.create_relationship_to(self, attrs)
    end

    def get_players()
      rels(:incoming, :plays_for)
    end

    def remove_player(user)
      rel = user._data.plays_for_rels.to_other(self).first
      rel.destroy if rel
    end

    def get_player_for_user(user)
      return unless user.persisted? && self.persisted?
      user._data.plays_for_rels.to_other(self).first
    end

    def get_player_by_kyck_id(player_kyck_id)
      self.get_players.select {|p| p.kyck_id == player_kyck_id}.first
    end

  end

end

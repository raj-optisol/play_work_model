module Messageable

  module Model
    def get_all_recipients()
      # wrap _data.get_players()
    end

    def get_player_recipients(user)
      # st = _data.get_player_for_user(user) 
      # wrap st
    end

    def get_player_by_id(player_id)
      wrap _data.get_player_by_id(player_id)
    end

  end


  module Data

    # def add_player(user, attrs={})
    #   rel = get_player_for_user(user)
    #   return rel if rel
    #   user._data.plays_for_rels.connect(self, attrs)
    # end
    # 
    # def get_players()
    #   rels(:incoming, :plays_for)
    # end
    # 
    # def remove_player(user)
    #   rel = user._data.plays_for_rels.to_other(self).first
    #   rel.destroy if rel
    # end
    # 
    # def get_player_for_user(user)
    #   return unless user.persisted? && self.persisted?
    #   user._data.plays_for_rels.to_other(self).first
    # end
    # 
    # def get_player_by_id(player_id)
    #   get_players.select {|p| p.id == player_id}.first
    # end

  end

end

class Roster
  include Edr::Model
  include BaseModel::Model
  include Staffable::Model
  include Playable::Model


  wrap_associations :players, :staff, :team, :competition_entry
  def_delegators :_data, :remove_staff

  def_delegators :_data, :remove_player
  def_delegators :_data, :viewable_by?
  def_delegators :_data, :locked?
  def_delegators :_data, :official?

  def organization
    team.organization
  end

  def player_count
    players.count
  end

  def sanctioned?
    organization.sanctioned? || (competition_entry.present? && competition_entry.competition.sanctioned?)
  end
end

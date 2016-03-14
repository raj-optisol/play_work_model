class Division
  include Edr::Model
  include BaseModel::Model

  def_delegators :_data, :add_roster, :remove_roster
  def_delegators :_data, :lock_rosters, :unlock_rosters
  def_delegators :_data, :viewable_by?, :unlock_rosters

  wrap_associations :competition, :rosters
end

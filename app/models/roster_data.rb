class RosterData < BaseModel::Data
  include Staffable::Data
  include Playable::Data
  property :name
  property :official, :type => :boolean, default: false
  property :locked, :type => :boolean, default: false
  property :destroyed, :type => :boolean, default: false

  has_n(:staff).from(:staff_for)
  has_n(:players).from(:plays_for)
  has_one(:team).from(TeamData, :rosters)

  has_one(:competition_entry).from(CompetitionEntryData, :roster)

  validates :name, presence: true

  def viewable_by?(user, rels=[])
    return true if user.admin?

    return true unless players.select { |u| u.id.to_s == user.id.to_s}.empty?
    return true unless team.staff.select{|u| u.id.to_s == user.id.to_s}.empty?
    return true if user.can_manage?(team, manage_perms, false)
    false
  end

  def manage_perms
    [PermissionSet::MANAGE_ROSTER,
     PermissionSet::MANAGE_TEAM,
     PermissionSet::MANAGE_PLAYER]
  end

  def locked?
    return true if locked
    return false
    return false unless division.present?
    Time.now.utc.to_i > division.roster_lock_date
  end

  def official?
    official
  end

  def get_players(filters={})
    if filters[:conditions]
      ConditionBuilder::OrientGraph.build(players_rels.as_query, filters[:conditions]).edges.map {|e| e.wrapper}
    else
      players_rels
    end
  end
end

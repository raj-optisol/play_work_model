# encoding: UTF-8
class Team
  include BaseModel::Model
  include Edr::Model
  include Staffable::Model

  fields :name, :gender, :player_count, :destroyed, :avatar
  def_delegators :_data, :remove_staff
  def_delegators :_data, :viewable_by?
  def_delegators :_data, :get_roster_and_division_for_competition
  def_delegators :_data, :avatar?
  def_delegators :_data, :avatar_version

  wrap_associations(
    :staff,
    :rosters,
    :schedules,
    :competition_entries,
    :organization
  )

  def add_player(user, attrs = {})
    official_roster.add_player(user, attrs)
  end

  def remove_player(user)
    official_roster.remove_player(user)
  end

  def get_players(filters = {})
    official_roster.get_players(filters)
  end

  def player_count
    get_players.count
  end

  def open?
    open == true
  end

  def get_staff
    wrap _data.get_staff
  end

  def age_group
    return '' if open?
    return 'Adult' unless born_after

    now = Date.today
    born = organization.born_after if organization
    born ||= Date.new(now.year, 7, 1) # TODO: Keep an eye

    age = now.year - born_after.year
    age -= 1 if now.year == born.year + 1 # works as long as the org.born_after gets updated every year?

    "U#{age}"
  end

  def age_group_number
    return 0 if open?
    if age_group == 'Adult'
      25
    else
      age_group[1, age_group.length - 1].try(:to_i)
    end
  end

  def staff_count
    get_staff.count
  end

  def get_events
    ScheduleRepository::EventRepository.get_events_for_obj(self)
  end

  def event_count
    get_events.count
  end

  def get_roster_by_id(roster_id)
    rosters.select { |roster| roster.id == roster_id }.first
  end

  def get_roster_by_kyck_id(roster_id)
    rosters.select { |roster| roster.kyck_id == roster_id }.first
  end

  def get_roster_by_name(name)
    rosters.select { |roster|  roster.name == name }.first
  end

  def roster_count
    rosters.count
  end

  def official_roster
    rosters.select { |roster|  roster.official? }.first
  end

  def competition_count
    rosters.select { |ros| ros.division.present? }.count
  end

  def competition_request_count
    competition_entries.select { |c| c.status != :approved }.count
  end

  def create_roster(attrs)
    get_roster_by_name(attrs[:name]) ||
      wrap(association(:rosters).create(attrs))
  end

  def clone_roster(roster, attrs = {})
    cloned =  (wrap association(:rosters).create(attrs))
    roster.get_players.each do |p|
      props = p._data.props.dup
      props.delete('kyck_id')
      cloned.add_player(p.user, props)
    end
    cloned
  end

  def create_schedule(attrs)
    wrap association(:schedules).create(attrs)
  end

  def master_schedule!
    schedules.select { |s| s.kind == :master }.first ||
      create_schedule(
        name: 'Master',
        kind: :master,
        start_date: DateTime.now)
  end

  def can_request_cards
    organization.sanctioned? || sanctioned_competitions.any?
  end

  def sanctioned_competitions
    competition_entries.select { |c| c.status == :approved }.select do |c|
      c.competition.sanctioned?
    end.map(&:competition)
  end

  def staff_roles
    ['Coach', 'Assistant Coach', 'Manager', 'Trainer', 'Other']
  end

  def available_permission_sets
    PermissionSet.for_team
  end

  def get_or_create_master_schedule()
    schedules.select { |s| s.kind == :master }.first ||
      begin
        create_schedule(name: "Master", kind: :master, start_date: DateTime.now)
    end
  end
end

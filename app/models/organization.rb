class Organization
  include Edr::Model
  include BaseModel::Model
  include Staffable::Model
  include Locatable::Model
  include Documentable::Model

  def_delegators :_data, :remove_staff
  def_delegators :_data, :avatar?
  def_delegators :_data, :add_team
  def_delegators :_data, :add_competition
  def_delegators :_data, :viewable_by?
  def_delegators :_data, :remove_team
  def_delegators :_data, :sanctioned?
  def_delegators :_data, :pending_sanction?

  wrap_associations(
    :staff,
    :teams,
    :competitions,
    :sanctioning_requests,
    :locations,
    :sanctioning_bodies,
    :cards,
    :sb_rep,
    :documents
  )

  def create_team(attrs)
    wrap association(:teams).create(attrs)
  end

  def add_player(user, attrs = {})
    open_team.add_player(user, attrs)
  end

  def remove_player(user)
    open_team.remove_player(user)
    teams.each { |t| t.remove_player(user) }
  end

  def get_players(input = {})
    OrganizationRepository::PlayerRepository.get_players(self, input)
  end

  def get_player_by_kyck_id(player_kyck_id)
    get_players(kyck_id: player_kyck_id).first
  end

  def players
    get_players
  end

  def staff_roles
    %w(Registrar President Director Manager Trainer Other)
  end

  def available_permission_sets
    PermissionSet.for_organization()
  end

  def uscs_admin
    sb = SanctioningBodyRepository.all.first
    state = sb.states.find { |s| s.abbr == self.state } if sb

    admin = nil
    if state
      admin = state.get_staff.find do |s|
        /admin/i === s.title || /admin/i === s.role
      end

      admin = admin.user if admin
    end

    admin
  end

  def uscs_rep
    sb = SanctioningBodyRepository.all.first
    state = sb.states.find{|s| s.abbr == self.state} if sb

    rep = nil
    if state
      rep = state.get_staff.find do |s|
        /representative/i === s.title || /representative/i === s.role
      end

      rep = rep.user if rep
    end
    
    rep
  end

  def open_team
    OrganizationRepository::TeamRepository.open_team_for_org!(self)
  end
end

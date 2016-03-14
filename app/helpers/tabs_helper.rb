require 'json'

module TabsHelper
  def build_tabs(org, team=nil, competition=nil, division=nil)
    return [] if !current_user
    return [] unless org || competition
    tabs = base_tabs((org || competition).kyck_id)

    if division && division.persisted?
      division_tabs(division, tabs)
    elsif team && team.persisted?
      tabs = team_tabs(team, tabs, org)
    elsif competition && competition.persisted?
      competition_tabs(competition, tabs)
    else
      organization_tabs(org, tabs)
    end
  end

  def organization_tabs(org, tabs)
    base_url = "/organizations/#{org.kyck_id}"
    tabs[:overview] = overview_tab(base_url)
    tabs[:staff] = staff_tab(base_url, org)
    tabs[:teams] = teams_tab(base_url, org)
    tabs[:players] = players_tab(base_url) if current_user.can_manage?(org, [PermissionSet::MANAGE_PLAYER])
    if org.sanctioned?
      tabs[:cards] =  cards_tab(base_url, org) if current_user.can_manage?(org, [PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD ], false)
    else
      tabs[:cards] = {title: 'Cards', href: "#{base_url}/cards/overview", icon:'icon-home', state:'cards' } if current_user.can_manage?(org, [PermissionSet::MANAGE_REQUEST], false)
    end
    tabs[:orders] =  orders_tab(base_url) if current_user.can_manage?(org, [PermissionSet::MANAGE_MONEY])
    tabs
  end

  def overview_tab(base_url)
    {title: 'Overview', href: base_url, icon: 'icon-home'}
  end

  def teams_tab(base_url, org)
    if current_user.can_manage?(org, [PermissionSet::MANAGE_TEAM], false)
      sublinks = []
      sublinks << {title: 'View All Teams', href: "#{base_url}/teams" }
      sublinks << {title: 'Add New Team', href: "#{base_url}/teams/new" }
      { title: 'Teams', href: "#{base_url}/teams", icon:'icon-home', sublinks: JSON.generate(sublinks) }
    else
      { title: 'Teams', href: "#{base_url}/teams", icon:'icon-home' }
    end
  end

  def team_staff_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Staff', href: "#{base_url}/staff" }
    sublinks << {title: 'Add New Staff', href: "#{base_url}/staff/new" }
    { title: 'Staff', href: "#{base_url}/staff", icon:'icon-home', sublinks: JSON.generate(sublinks) }
  end

  def team_players_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Players', href: "#{base_url}/players" }
    sublinks << {title: 'Add New Player', href: "#{base_url}/players/new" }
    { title: 'Players', href: "#{base_url}/players", icon:'icon-home', state: 'players', sublinks: JSON.generate(sublinks) }
  end

  def team_cards_tab(base_url, team)
    sublinks = []
    sublinks << {title: 'Request Cards', href: "#{base_url}/card_requests/new", state:'cards'} if current_user.can_manage?(team, [PermissionSet::REQUEST_CARD], false)
    sublinks << {title: 'Print Cards', href: "#{base_url}/cards", state:'cards'} if current_user.can_manage?(team, [PermissionSet::PRINT_CARD], false)
    sublinks << {title: 'Previous Requests', href: "#{base_url}/card_requests", state:'cards'} if current_user.can_manage?(team, [PermissionSet::REQUEST_CARD])
    {title: 'Cards', href: "#{base_url}/cards/overview", icon:'icon-home', state:'cards', sublinks: JSON.generate(sublinks) }
  end

  def staff_tab(base_url, org)
    if current_user.can_manage?(org, [PermissionSet::MANAGE_STAFF], false)
      sublinks = []
      sublinks << {title: 'View All Staff', href: "#{base_url}/staff" }
      sublinks << {title: 'Add New Staff', href: "#{base_url}/staff/new" }
      { title: 'Staff', href: "#{base_url}/staff", icon:'icon-home', sublinks: JSON.generate(sublinks) }
    else
      { title: 'Staff', href: "#{base_url}/staff", icon:'icon-home' }
    end
  end

  def competition_staff_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Staff', href: "#{base_url}/staff" }
    sublinks << {title: 'Add New Staff', href: "#{base_url}/staff/new" }
    { title: 'Staff', href: "#{base_url}/staff", icon:'icon-home', sublinks: JSON.generate(sublinks) }
  end

  def competition_cards_tab(base_url)
    sublinks = []
    sublinks << {title: 'Manage Cards', href: "#{base_url}/cards/manage", state:'cards'}
    sublinks << {title: 'Print Cards', href: "#{base_url}/cards", state:'cards'}
    {title: 'Cards', href: "#{base_url}/cards/overview", icon:'icon-home', state:'cards', sublinks: JSON.generate(sublinks) }
  end

  def players_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Players', href: "#{base_url}/players", state: 'players' }
    sublinks << {title: 'Add New Player', href: "#{base_url}/players/new", state: 'players' }
    sublinks << {title: 'Import Players', href: "#{base_url}/import_processes/new?ref=players", state: 'players' }
    { title: 'Players', href: "#{base_url}/players", icon:'icon-home', state: 'players', sublinks: JSON.generate(sublinks) }
  end

  def rosters_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Rosters', href: "#{base_url}/rosters", state:'rosters' }
    sublinks << {title: 'Add New Roster', href: "#{base_url}/rosters/new", state:'rosters' }
    {title: 'Rosters', href: "#{base_url}/rosters", icon:'icon-home', state:'rosters', sublinks: JSON.generate(sublinks) }
  end

  def cards_tab(base_url, org)
    sublinks = []
    sublinks << {title: 'Request Cards', href: "#{base_url}/card_requests/new", state:'cards'} if current_user.can_manage?(org, [PermissionSet::REQUEST_CARD])
    sublinks << {title: 'Print Cards', href: "#{base_url}/cards", state:'cards'}               if current_user.can_manage?(org, [PermissionSet::PRINT_CARD])
    sublinks << {title: 'Previous Requests', href: "#{base_url}/card_requests", state:'cards'} if current_user.can_manage?(org, [PermissionSet::REQUEST_CARD])
    {title: 'Cards', href: "#{base_url}/cards/overview", icon:'icon-home', state:'cards', sublinks: JSON.generate(sublinks) }
  end

  def orders_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Orders', href: "#{base_url}/orders", state:'orders' }
    sublinks << {title: 'Make A Deposit', href: "#{base_url}/deposits/new", state:'orders' }
    {title: 'Orders', href: "#{base_url}/orders", icon:'icon-home', state:'orders', sublinks: JSON.generate(sublinks) }
  end

  def competitions_tab(base_url)
    sublinks = []
    sublinks << {title: 'View All Competitions', href: "#{base_url}/entries"}
    sublinks << {title: 'Find New Competitions', href: "#{base_url}/competitions"}
    {title: 'Competitions', href: "#{base_url}/entries", icon:'icon-home', state:'team_competitions', sublinks: JSON.generate(sublinks) }
  end

  def division_tabs(division, tabs)
    base_url = "/divisions/#{division.kyck_id}"
    tabs[:overview] = overview_tab(base_url)
    tabs[:teams] = entries_tab(base_url)
    tabs
  end

  def entries_tab(base_url)
    { title: 'Teams', href: "#{base_url}/entries", icon:'icon-home' }
  end

  def team_tabs(team, tabs, org)
    base_url = "/teams/#{team.kyck_id}"
    tabs[:overview]     = overview_tab(base_url)
    tabs[:staff]        = team_staff_tab(base_url)   if !team.open? && current_user.can_manage?(team, [PermissionSet::MANAGE_STAFF])
    tabs[:rosters]      = rosters_tab(base_url)      if !team.open? && current_user.can_manage?(team, [PermissionSet::MANAGE_ROSTER])
    tabs[:players]      = team_players_tab(base_url) if current_user.can_manage?(team, [PermissionSet::MANAGE_PLAYER])
    if org.sanctioned?
      tabs[:cards]      = team_cards_tab(base_url, team)   if team.can_request_cards && current_user.can_manage?(team, [PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD], false)
    else
      tabs[:cards]      = {title: 'Cards', href: "#{base_url}/cards/overview", icon:'icon-home', state:'cards' } if current_user.can_manage?(team, [PermissionSet::MANAGE_CARD, PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD, PermissionSet::REQUEST_PLAYER_CARD, PermissionSet::REQUEST_STAFF_CARD], false)
    end
    tabs[:competitions] = competitions_tab(base_url) if !team.open? && current_user.can_manage?(team, [PermissionSet::MANAGE_REQUEST]) || !team.open? && current_user.can_manage?(team, [PermissionSet::MANAGE_TEAM])
    tabs
  end

  def competition_tabs(competition, tabs)
    puts "COMP TABS"
    base_url = "/competitions/#{competition.kyck_id}"
    tabs[:overview]  = overview_tab(base_url)
    tabs[:staff]     = competition_staff_tab(base_url)                                         if current_user.can_manage?(competition, [PermissionSet::MANAGE_STAFF])
    tabs[:teams]     = entries_tab(base_url)                                                   if current_user.can_manage?(competition, [PermissionSet::MANAGE_TEAM])
    tabs[:divisions] = {title: 'Divisions', href: "#{base_url}/divisions", icon:'icon-home'}   if current_user.can_manage?(competition, [PermissionSet::MANAGE_ROSTER])
    if competition.can_process_cards_for_sb?
      tabs[:cards]   = competition_cards_tab(base_url)                                         if current_user.can_manage?(competition, [PermissionSet::MANAGE_REQUEST, PermissionSet::MANAGE_CARD], false)
    end
    tabs
  end

  def base_tabs(org_id)
    return {} unless org_id
    { overview: {title: 'Overview', href:'/organizations/'+org_id, icon:'icon-home'},
     staff:false,
     teams:false,
     players:false,
     cards:false}
  end

  def can_manage_reports?(sanctioning_body)
    current_user.can_manage?(
      sanctioning_body,
      [PermissionSet::RUN_FINANCIAL_REPORT]
    )
  end

  def build_sanctioning_body_tabs(sanctioning_body, state=nil)
    tabs = {}
    if state
      tabs[:overview] = {title: 'Overview', href:'/states/'+state.kyck_id, icon:'icon-home'}
      tabs[:staff] = {title: 'Staff', href:'/states/'+state.kyck_id+'/staff', icon:'icon-home'}
      tabs[:sanction] = {title: 'Sanctions', href:'/states/'+state.kyck_id+'/sanctions', icon:'icon-home'}
    else
      tabs[:overview] = {title: 'Overview', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id, icon:'icon-home'}
      if current_user.can_manage?(sanctioning_body, [PermissionSet::MANAGE_MONEY])
        tabs[:states] = {title: 'States', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/states', icon:'icon-home'}
        tabs[:staff] = {title: 'Staff', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/staff', icon:'icon-home'}
      end
      if current_user.can_manage?(sanctioning_body, [PermissionSet::MANAGE_REQUEST])
        tabs[:sanction] = {title: 'Sanctions', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/sanctions', icon:'icon-home', state: 'sanctions'}
        tabs[:sanctioning_requests] = {title: 'Sanctioning Requests', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/sanctioning_requests', icon:'icon-home'}
        tabs[:cards] = {title: 'Cards', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/cards/overview', icon:'icon-home', state: 'cards'}
      end
      tabs[:fees] = {title: 'Fees', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/fees/overview', icon:'icon-home', state:'fee'} if current_user.can_manage?(sanctioning_body, [PermissionSet::MANAGE_MONEY])
      tabs[:reports] = { title: 'Reports', href:'/sanctioning_bodies/'+sanctioning_body.kyck_id+'/reports/overview', icon:'icon-home', state:'reports' } if current_user.can_manage?(sanctioning_body, [PermissionSet::RUN_FINANCIAL_REPORT])
    end
    tabs
  end
end

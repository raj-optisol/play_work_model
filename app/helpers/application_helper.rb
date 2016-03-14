# encoding: UTF-8
module ApplicationHelper

  def application_renderable?
    ['terms', 'privacy', 'help'].include?(controller.action_name) || account_signed_in?
  end

  def cache_if (condition, name = {}, &block)
    if condition
      cache(name, &block)
    else
      yield
    end
  end

  def staffed_item_new_path(org)
    case
    when params[:organization_id]
      new_organization_staff_path(org)
    when params[:sanctioning_body_id]
      new_sanctioning_body_staff_path(org)
    else
      root_url
    end
  end

  def build_tabs(org, season=nil, team=nil, competition=nil, division=nil)
    return [] if !current_user
    return [] if !org || !org.persisted?

    org_id = org.kyck_id.to_s

    tabs = {overview: {title: 'Overview', href:'/organizations/'+org_id, icon:'icon-home'},
            staff:false,
            teams:false,
            players:false,
            cards:false}

    if division && division.persisted?
      div_id = division.kyck_id.to_s
      tabs[:overview] = {title: 'Overview', href:'/divisions/'+div_id, icon:'icon-home'}
      tabs[:teams] = {title: 'Teams', href:'/divisions/'+div_id+'/entries', icon:'icon-home'}

    elsif team && team.persisted?
      team_id = team.kyck_id.to_s
      tabs[:overview] = {title: 'Overview', href:'/teams/'+team_id, icon:'icon-home'}
      tabs[:players] = {title: 'Players', href:'/teams/'+team_id+'/players', icon:'icon-home', state:'players' }
      tabs[:rosters] = {title: 'Rosters', href:'/teams/'+team_id+'/rosters', icon:'icon-home', state:'rosters'}
      tabs[:staff] =  {title: 'Staff', href:'/teams/'+team_id+'/staff', icon:'icon-home'}
      tabs[:competitions] = {title: 'Competitions', href:'/teams/'+team_id+'/entries', icon:'icon-home', state:'team_competitions'}
      # tabs[:events] = {title: 'Events', href:'/teams/'+team_id+'/events', icon:'icon-home'}
      #tabs[:messages] = {title: 'Messages', href:'/teams/'+team_id+'/messages', icon:'icon-home'}
      #tabs[:messages] = {title: 'Messages', href:'/teams/'+team_id+'/messages', icon:'icon-home', disabled:'disabled'}
      tabs[:cards] =  {title: 'Cards', href:'/teams/'+team_id+'/cards/overview', icon:'icon-home', state:'cards'} if team.can_request_cards() && current_user.can_manage?(team, [PermissionSet::MANAGE_CARD, PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD, PermissionSet::REQUEST_PLAYER_CARD, PermissionSet::REQUEST_STAFF_CARD], false)

    elsif competition && competition.persisted?
      comp_id = competition.kyck_id.to_s
      tabs[:overview] = {title: 'Overview', href:'/competitions/'+comp_id, icon:'icon-home'}
      tabs[:divisions] = {title: 'Divisions', href:'/competitions/'+comp_id+'/divisions', icon:'icon-home'}
      tabs[:teams] = {title: 'Teams', href:'/competitions/'+comp_id+'/entries', icon:'icon-home'}
      tabs[:staff] =  {title: 'Staff', href:'/competitions/'+comp_id+'/staff', icon:'icon-home'}
      tabs[:cards] =  {title: 'Cards', href:'/competitions/'+comp_id+'/cards/overview', icon:'icon-home', state: 'cards'} if competition.can_process_cards_for_sb?() && current_user.can_manage?(competition, [PermissionSet::MANAGE_CARD, PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD, PermissionSet::REQUEST_PLAYER_CARD, PermissionSet::REQUEST_STAFF_CARD], false)
    else
      tabs[:overview] = {title: 'Overview', href:'/organizations/'+org_id, icon:'icon-home'}
      tabs[:teams] = {title: 'Teams', href:'/organizations/'+org_id.to_s+'/teams', icon:'icon-home'}
      tabs[:staff] =  {title: 'Staff', href:'/organizations/'+org_id+'/staff', icon:'icon-home'}
      tabs[:players] = {title: 'Players', href:'/organizations/'+org_id.to_s+'/players', icon:'icon-home'} if org_id != ''
      tabs[:cards] =  {title: 'Cards', href:'/organizations/'+org_id+'/cards/overview', icon:'icon-home', state:'cards'} if current_user.can_manage?(org, [PermissionSet::MANAGE_CARD, PermissionSet::REQUEST_CARD, PermissionSet::PRINT_CARD ], false)
      tabs[:competitions] = {title: 'Competitions', href:"/organizations/#{org_id}/competitions", icon:'icon-home'}
      tabs[:orders] =  {title: 'Orders', href:'/organizations/'+org_id+'/orders', icon:'icon-home', state:'orders'} if current_user.can_manage?(org, [PermissionSet::MANAGE_MONEY])
    end

    tabs
  end

  def build_sanctioning_body_tabs(sanctioning_body, state=nil)
    tabs = {}
    if state
      if current_user.can_manage?(sanctioning_body, [PermissionSet::MANAGE_ORGANIZATION])
        tabs[:overview] = {title: 'Overview', href:'/states/'+state.kyck_id, icon:'icon-home'}
        tabs[:staff] = {title: 'Staff', href:'/states/'+state.kyck_id+'/staff', icon:'icon-home'}
        tabs[:sanction] = {title: 'Sanctions', href:'/states/'+state.kyck_id+'/sanctions', icon:'icon-home'}
      end

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
    end

    tabs
  end

  def link_to_edit(obj, permissions, *linkargs)
    @editperms ||= {}
    @editperms[obj.id+permissions.join('')] ||= current_user.can_manage?(obj, permissions)
    return '' unless @editperms[obj.id+permissions.join('')]
    link_to *linkargs
  end

  def get_transaction_name(t, payer, payee, kind='source')
    opts = ['source', 'destination', 'kind']
    name = case kind
           when 'source'
             (t.status=='refunded' ? payee.name : (!t.transaction_id ? (t.kind=='liability' && t.transaction_type=='debit' ? 'Balance' : payee.name) : 'Credit Card'))
           when 'destination'

             if t.status == 'refunded'

               if t.transaction_id
                 'Credit Card'
               else
                 if t.kind == 'liability' && t.transaction_type == 'credit'
                   'Balance'
                 else
                   payer.name
                 end
               end
             else
               destname = payee.name
               if t.transaction_id
                 if t.kind == 'liability' && t.transaction_type == 'credit'
                   destname = 'Balance'
                 else
                   payee.name
                 end
               end
               destname
             end
           when 'kind'
             if t.status == 'refunded'
               'Refund'
             elsif t.kind == 'liability' && t.transaction_type == 'credit'
               'Deposit'
             else
               'Payment'
             end

           end # END CASE
    name
  end

  def get_org_uscs_admin(org)
    Rails.cache.fetch("uscs_admin_for_#{org.kyck_id}", :expires_in => 1.day) do
      admin = org.uscs_admin
      return unless admin

      { id: admin.kyck_id,
        updated_at: admin.updated_at,
        name: admin.full_name,
        email: admin.email,
        phone: admin.phone_number,
        avatar: admin.avatar
      }
    end
  end

  def get_org_uscs_rep(org)
    Rails.cache.fetch("uscs_rep_for_#{org.kyck_id}", expires_in: 1.day) do
      rep = org.sb_rep || org.uscs_rep
      return unless rep

      { id: rep.kyck_id,
        updated_at: rep.updated_at,
        name: rep.full_name,
        email: rep.email,
        phone: rep.phone_number,
        avatar: rep.avatar
      }
    end
  end
end

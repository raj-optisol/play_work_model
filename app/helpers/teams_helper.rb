module TeamsHelper
  def new
    @team= Team.build.extend(TeamRepresenter)
    render template: 'teams/new', has_ajax: false
  end

  def index
    respond_to do |format|
      format.html { render template: 'teams/index' }
      format.json do
        options = view_context.default_query_options(params)
        options.reverse_merge!(
          order: 'name',
          order_dir: 'asc'
        )
        action = KyckRegistrar::Actions::GetTeams.new current_user, @obj
        @teams = action.execute(options)
        can_manage_teams = current_user.can_manage?(@obj, [PermissionSet::MANAGE_TEAM])
        remove_open_team!
        respond_with(@teams,
                     represent_items_with: index_representer,
                     manage_all:can_manage_teams)
      end
    end
  end

  def edit
    unless current_user.can_manage?(@team, [PermissionSet::MANAGE_TEAM]) &&
      !@team.open?
      redirect_to organization_teams_path(@org)
      return
    end
    respond_to do |format|
      format.html { respond_with @team.extend(TeamRepresenter) }
      format.json { respond_with @team.extend(TeamRepresenter) }
    end
  end


  private

  def remove_open_team!
    @teams = @teams.select { |team| team.name != 'Open Team' }
  end

  def index_representer
    params[:lite] ? NameRepresenter : TeamRepresenter
  end
end

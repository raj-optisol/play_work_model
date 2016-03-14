module PlayersHelper

  def new
    @player = Player.build
    get_birthday_validation_parameters
    @can_edit = (@player.user ? !@player.user.claimed? : true )
    @player.extend(PlayerRepresenter)
    render template: 'players/new', has_ajax: false
  end

  def create
    action = KyckRegistrar::Actions::AddPlayer.new(current_user, @obj)

    respond_to do |format|
      format.html{
        action.on(:player_created) do |player|
          flash[:notice] = "Player Saved"
          redirect_to :action => :new
        end

        action.on(:max_players_reached) do |team|
          flash[:error] = "The maximum number of players has been reached for #{team.name}."
          redirect_to :action => :index
        end

        action.on(:invalid_player) do |staff|
          flash[:error] = "The user is invalid #{staff.errors.full_messages}"
          session[:validate_player] = true
          redirect_to :action => :new
        end
        @player = action.execute(player_params)
      }
      format.json {
        @player = action.execute(player_params)
        @player.extend(PlayerRepresenter) if @player
        respond_with @player
      }
    end
  end

  def edit
    action = KyckRegistrar::Actions::GetPlayers.new(current_user, @obj)
    conds = {player_conditions: { kyck_id: params[:id] } }
    players = action.execute(conds)

    return not_found unless players.count == 1

    @player = players.first
    get_birthday_validation_parameters
    @can_edit = !@player.user.claimed?
    @player.extend(PlayerRepresenter)
    render template: 'players/edit', has_ajax: false
  end

  def destroy
    unless Flip.remove_players?
      fail ActionController::RoutingError, 'Not Found'
    end

    handler = CardHandler.new
    action = remove_action
    action.subscribe handler, on: :cards_released, with: :release_cards
    action.execute id: params[:id]
    respond_to do |format|
      format.html do
        redirect_to url_for [@obj, :players]
      end
      format.json do
        head :ok
      end
    end
  end

  def remove_action
    if open_roster?
      KyckRegistrar::Actions::ReleasePlayer.new current_user, @org, params[:id]
    else
      KyckRegistrar::Actions::RemovePlayer.new current_user, @player.playable
    end
  end

  def open_roster?
    @player.playable.team.open?
  end

  def update
    action = KyckRegistrar::Actions::UpdatePlayer.new(
      current_user,
      @obj,
      params[:id]
    )

    Rails.logger.info "URL = #{url_for([@obj, :players])}"
    respond_to do |format|
      format.html do
        action.on(:player_updated) do |player|
          redirect_to url_for([ @obj, :players  ])
        end

        action.on(:invalid_player) do |player|
          redirect_to action: :edit
        end
        action.execute player_params
      end
      format.json do
        @player = action.execute player_params
        respond_with @player.extend(PlayerRepresenter)
      end
    end
  end

  def player_params
    input = params[:player].slice(
      'first_name',
      'last_name',
      'parent_email',
      'email',
      'user_id',
      'gender',
      'birthdate',
      'position',
      'jersey_number',
      'phone_number',
      'team',
      'middle_name',
      'address1',
      'address2',
      'city',
      'state',
      'zipcode',
      'suffix',
      'avatar',
      'avatar_uri',
      'avatar_version',
      'documents'
    )
    input
  end

  def strip_keys!
    %w(first_name last_name).each do |key|
      params[:player][key].strip! if params.fetch(:player, {})[key]
    end
  end

  def get_birthday_validation_parameters
    @age_group = ''
    if @team
      @age_group = @team.age_group
    elsif @player && @player.user
      @age_group = @player.playable.team.age_group
    end

    @teams = {}
    if @org
      @org.teams.each do |i|
        @teams[i.kyck_id] = {born_after: i.born_after, gender: i.gender}
      end
    end
    @is_carded = carded?
  end

  def player_record
    @player = OrganizationRepository::PlayerRepository.find(kyck_id: params[:id])
  end

  def search_parameters
    search_params = {}
    parse_filters

    filters = params.delete(:filter)
    if filters
      search_params = team_filters(filters)
      search_params = user_filters(filters, search_params)
    end
    search_params
  end

  def carded?
    @player &&
      @player.user &&
      !@player.user.cards.empty? &&
      @player.user.cards.first.status == :approved
  end

  # Check player has pending/new card status
  def can_release_player
    pending_card = @player && @player.user.cards.present? && @player.user.cards.any?{|card| card.status == :new }
    render json:{result: pending_card}
  end

  def sql_for_players_and_teams(player_ids)
    'select from (select kyck_id, $teams["map"] as teams from ' \
      "(select expand(out) from #{player_ids.to_s.gsub('"', '')})" \
      ' let $teams = (select map("name", name, "kyck_id", kyck_id) ' \
      'from (traverse in_Team__rosters from (traverse in, out_plays_for' \
      ' from $parent.$parent.$current)) where @class="Team" and ' \
      "in_Organization__teams.@rid = #{@org._data.id}))"
  end

  def authenticate_for_players!(cntrller)
    authenticate_with_permissions!(
      cntrller,
      PermissionSet::MANAGE_PLAYER,
      false,
      @obj
    )
  end
end

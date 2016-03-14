module CardStatusRepository
  extend CommonFinders::OrientGraph

  def self.define_pipe_function(&block)
    func = KyckPipeFunction.new
    func.send(:define_singleton_method, :compute) { |it| yield it }
  end

  def self.card_status_pipeline(gp, card_type, &conditional_block)
    teams = []
    conditional_func = define_pipe_function(&(conditional_block.call teams))

    true_func = define_pipe_function do |it|
      # We have teams, so our card status needs them
      CardStatus.new(
        CardStatusRepository.wrap_user it.wrapper,
        card_type,
        teams.map { |t| CardStatusRepository.wrap_team t.wrapper }
      )
    end

    false_func = define_pipe_function do |it|
      # No teams for this user, they are just on the org
      CardStatus.new CardStatusRepository.wrap_user it.wrapper
    end

    gp.outV.if_then_else(
      conditional_func,
      true_func,
      false_func
    )
  end

  def self.get_uncarded_for_sb_and_item(_sb, item, input = {})
    sql = sql_for_item item, input
    cmd = OrientDB::SQLSynchQuery.new(sql).set_fetch_plan(
      'out_plays_for:1 out_staff_for:1 out_User__documents:1'
    )
    results = []
    results = Oriented.graph.command(cmd).execute
    results.map do |it|
      CardStatus.new CardStatusRepository.wrap_user it.wrapper
    end
  end

  def self.sql_for_item(item, input = {})
    organization = case item
                   when Team
                     item.organization._data
                   else
                     item._data
                   end

    sql = case item
          when Team
            'select from (select expand(out) from (traverse in_plays_for, ' +
              "from (traverse out_Team__rosters from #{item.id})) "
          else
            if input[:team_conditions]
              'select from (select expand(distinct(out)) from (' +
                'traverse in_plays_for, in_staff_for, out_Team__rosters ' +
                'from (select from (traverse out_Organization__teams ' +
                "from #{organization.id}) "
            else
              'select from (select expand(distinct(out)) from (traverse ' +
                'in_plays_for, in_staff_for, out_Team__rosters, ' +
                "out_Organization__teams from #{organization.id}" +
                ') '
            end
          end

    # team filtering
    if input[:team_conditions]
      sql = "#{sql} where #{build_sql_filters(input[:team_conditions])})) "
    else
      sql = "#{sql} "
    end

    t_one = (Time.now+1.month).to_i
    # Handle user filtering
    sql = sql + ') let $cfor = (select @rid from ' \
      '$parent.$current.in_Card__carded_user where status in ["new", ' \
      '"approved", "requestor_response_required" ] and ' \
      "expires_on > #{t_one} and " \
      "out_Card__carded_for.@rid = #{organization.id}) where $cfor.size() = 0 "

    if input[:user_conditions]
      sql = "#{sql} and #{build_sql_filters(input[:user_conditions])}"
    end

    if input[:order] && input[:order] == 'user'
      input[:order] = 'last_name'
    end

    "#{sql} #{build_sql_options(input)} "
  end

  #
  # Get cards for players that are carded for the specified
  # sanctioning body and item.
  #
  # Probably should move this to CardRepository
  def self.get_player_cards_pipeline_for_sb_and_item(sb, item, input = {})
    organization = item
    input[:onlyplays] = "sub"
    pipeline = OrganizationRepository::PlayerRepository.player_pipeline_for(
      item,
      input
    )

    # Have to be on a roster to get a card
    pipeline.outV.dedup.in(
      CardData.relationship_label_for :carded_user
    ).filter { |it| it['kind'] == 'player' }.out(
      CardData.relationship_label_for :carded_for
    ).filter { |it| it['kyck_id'] == organization.kyck_id }.back 5
  end

  def self.get_uncarded_players_pipeline_for_sb_and_item(_sb, item, opts = {})
    user_filters = opts[:user_conditions] || {}
    team_filters = opts[:team_conditions] || {}

    gp = start_query_with(item)

    organization = item.is_a?(Organization) ? item : item.organization

    gp.out(OrganizationData.relationship_label_for(:teams))
    gp.out(TeamData.relationship_label_for(:rosters))
    gp.inE(UserData.relationship_label_for(:plays_for)).as('players')

    unless team_filters.empty?
      gp.outV.out('plays_for').filter { |bit| bit['@class'] == 'Roster' }
      gp.in TeamData.relationship_label_for :rosters
      gp = ConditionBuilder::OrientGraph.build gp, team_filters
      gp.back 'players'
    end

    unless user_filters.empty?
      gp.outV
      gp = ConditionBuilder::OrientGraph.build gp, user_filters
      gp.back 'players'
    end

    no_cards_pipeline = KyckPipeline.new Oriented.graph
    cards_for_other_orgs = KyckPipeline.new Oriented.graph

    key_function = KyckPipeFunction.new
    key_function.send :define_singleton_method, :compute do |it|
      kid = KyckPipeline.new(Oriented.graph)._.start(it).out(
        CardData.relationship_label_for :carded_for
      ).transform { |cf| cf['kyck_id'] }.to_a
      kid = kid.first if kid
      "#{it['kind']}::#{kid}"
    end

    gp.outV.dedup.or(
      no_cards_pipeline._.filter do |it|
        it.get_edges(
          Oriented::Relationships::Direction::IN, 'Card__carded_user'
        ).count ==0
      end,
      cards_for_other_orgs._.filter do |it|
        grouped_res = {}
        other_cards_for_org = KyckPipeline.new Oriented.graph
        other_cards_for_org._.start(it).in(
          CardData.relationship_label_for(:carded_user)
        ).filter do |c|
          c['status'] == 'approved' && c['expires_on'] >= Time.now.to_i
        end.group_count(grouped_res, key_function).to_a
        !grouped_res["player::#{organization.kyck_id}"] ||
          grouped_res["player::#{organization.kyck_id}"] == 0
      end
    ).back 3
  end

  def self.get_uncarded_staff_pipeline_for_sb_and_item(_sb, item, input = {})
    pipeline = OrganizationRepository::StaffRepository.staff_pipeline_for(
      item,
      input
    )

    # Have to be on a team to be eligible for a card
    # staff_pipeline.filter{|it| it.end_vertex["@class"] == "Team"}
    organization = item

    no_cards_pipeline = KyckPipeline.new Oriented.graph
    cards_for_other_orgs = KyckPipeline.new Oriented.graph

    key_function = KyckPipeFunction.new
    key_function.send :define_singleton_method, :compute do |it|
      kid = KyckPipeline.new(Oriented.graph)._.start(it).filter do |fit|
        fit['status'] != 'inactive'
      end.out(
        CardData.relationship_label_for(:carded_for)
      ).transform { |cf| cf['kyck_id'] }.to_a
      kid = kid.first if kid
      "#{it['kind']}::#{kid}"
    end

    pipeline.as('staff').outV.dedup.or(
      no_cards_pipeline._.filter do |it|
        it.get_edges(
          Oriented::Relationships::Direction::IN,
          'Card__carded_user').count == 0
      end,
      cards_for_other_orgs._.filter do |it|
        grouped_res = {}
        other_cards_for_org = KyckPipeline.new Oriented.graph
        other_cards_for_org._.start(it).in(
          CardData.relationship_label_for(:carded_user)
        ).filter do |c|
          c['status'] == 'approved' && c['expires_on'] >= Time.now.to_i
        end.group_count(grouped_res, key_function).to_a
        !grouped_res["staff::#{organization.kyck_id}"] ||
          grouped_res["staff::#{organization.kyck_id}"] == 0
      end
    ).back 'staff'

    pipeline
  end

  def self.get_staff_cards_pipeline_for_sb_and_item(_sb, item, input = {})
    pipeline = OrganizationRepository::StaffRepository.staff_pipeline_for(
      item,
      input
    )

    organization = item

    pipeline.outV.dedup.in(
      CardData.relationship_label_for(:carded_user)
    ).filter do |it|
      it['kind'] == 'staff' && !%w(inactive denied).include?(it['status'])
    end
    pipeline.out(
      CardData.relationship_label_for(:carded_for)
    ).filter { |it| it['kyck_id'] == organization.kyck_id }.back 5
  end

  def self.card_status_summary_for_obj(sb, item)
    organization = item.is_a?(Organization) ? item : item.organization
    card_status = {}
    oid = organization._data.id

    card_status['uncarded_player_count'] = execute_sql(
      uncarded_player_count_sql(oid)
    ).first['count']

    card_status['carded_player_count'] = execute_sql(
      carded_player_count_sql(oid)
    ).first['count']

    card_status['uncarded_staff_count'] = execute_sql(
      uncarded_staff_count_sql(oid)
    ).first['count']

    card_status['carded_staff_count'] = execute_sql(
      carded_staff_count_sql(oid)
    ).first['count']

    card_status['carded'] = card_status['carded_player_count'] +
      card_status['carded_staff_count']
    card_status['uncarded'] = card_status['uncarded_player_count'] +
      card_status['uncarded_staff_count']

    card_status
  end

  def self.uncarded_staff_count_sql(oid)
    'select count(distinct(kyck_id)) from (select expand(out) from ' \
      '(traverse in_staff_for, out_Organization__teams, in_staff_for ' \
      "from  ##{oid})) let $crd = (select @rid from (" +
      'traverse out_Card__Carded_for from (traverse in_Card__carded_user ' \
      'from $parent.$parent.$current) while out_Card__carded_for.@rid ' \
      "= #{oid} and kind='staff' and status in ['approved', 'new'])) " \
      'where $crd.size() = 0'
  end

  def self.carded_staff_count_sql(oid)
    'select count(distinct(kyck_id)) from (select expand(out) from ' \
      '(traverse in_staff_for, out_Organization__teams, in_staff_for, ' \
      " from  ##{oid})) let $crd = (select @rid from (" \
      'traverse out_Card__Carded_for from (traverse in_Card__carded_user ' \
      'from $parent.$parent.$current) while out_Card__carded_for.@rid ' \
      "= #{oid} and kind='staff' and status in ['approved', 'new'])) " \
      'where $crd.size() > 0'
  end

  def self.uncarded_player_count_sql(oid)
    'select count(distinct(kyck_id)) from (select expand(out) from ' \
      '(traverse out_Organization__teams, out_Team__rosters, in_plays_for ' \
      "from  ##{oid})) let $crd = (select @rid from (" +
      'traverse out_Card__Carded_for from (traverse in_Card__carded_user ' \
      'from $parent.$parent.$current) while out_Card__carded_for.@rid ' \
      "= #{oid} and kind='player' and status in ['approved', 'new'])) " \
      'where $crd.size() = 0'
  end

  def self.carded_player_count_sql(oid)
    'select count(distinct(kyck_id)) from (select expand(out) from ' \
      '(traverse out_Organization__teams, out_Team__rosters, ' \
      "in_plays_for from  ##{oid})) let $crd = (select @rid from (" \
      'traverse out_Card__Carded_for from (traverse in_Card__carded_user ' \
      'from $parent.$parent.$current) while out_Card__carded_for.@rid ' \
      "= #{oid} and kind='player' and status in ['approved', 'new'])) " \
      'where $crd.size() > 0'
  end

  # private
  def self.wrap(obj)
    case obj
    when PlayerData
      wrap_player obj
    when StaffData
      wrap_staff obj
    else
      fail ArgumentError, 'Do not know how to wrap obj'
    end
  end

  def self.wrap_user(u)
    User.new.tap do |m|
      m.send :_data=, u
      m.send :repository=, UserRepository
    end
  end

  def self.wrap_team(u)
    Team.new.tap do |m|
      m.send :_data=, u
      m.send :repository=, OrganizationRepository::TeamRepository
    end
  end

  def self.wrap_player(p)
    Player.new.tap do |m|
      m.send :_data=, p
      m.send :repository=, OrganizationRepository::PlayerRepository
    end
  end

  def self.wrap_staff(s)
    Staff.new.tap do |m|
      m.send :_data=, s
      m.send :repository=, OrganizationRepository::StaffRepository
    end
  end
end

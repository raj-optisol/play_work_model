module OrganizationRepository
  module PlayerRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Player

    USER_ATTRIBUTES = %w(first_name last_name email)
    USER_ATTRIBUTES_REGEX = Regexp.new("#{USER_ATTRIBUTES.join('|')}")

    module PlayerType
      FOR = 1
      SUB = 2
      ALL = 3
    end

    def self.player_pipeline_for(obj, opts={}, current=true)
      player_rel_label = UserData.relationship_label_for(:plays_for)
      offset = opts.fetch(:offset, 0).to_i
      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 unless limit == 0

      user_filters = opts[:user_conditions] || {}
      player_filters = opts[:player_conditions] ||{}
      team_filters = opts[:team_conditions] ||{}

      @gp = start_query_with(obj._data)

      opts.symbolize_keys!

      onlyplays = opts.fetch(:onlyplays, 'for') # for, sub, all

      if (onlyplays == 'all')
        plays_for_gp = start_query_with(obj._data).inE(player_rel_label)
        sub_plays_for_gp = start_query_with(obj._data)
      elsif (onlyplays == 'for')
         @gp.inE(player_rel_label)
      elsif onlyplays == 'sub'
        sub_plays_for_gp = @gp
      end

      if onlyplays != 'for'
        while_pf, emit_pf = while_and_emit_pipe_functions(4)
        sub_plays_for_gp.outE.filter{|it| %w(Organization__teams Team__rosters).include?(it.label)}.inV.loop(3, while_pf, emit_pf).inE(player_rel_label)
      end

      if (onlyplays == 'all')

        @gp.copy_split(
          sub_plays_for_gp,
          plays_for_gp
        ).fairMerge
      end

      @gp = ConditionBuilder::OrientGraph.build(@gp, player_filters)

      unless team_filters.empty?
        if onlyplays == 'for'
          @gp.outV.outE(player_rel_label).inV.filter{|it| it['@class'] != Organization && (tgp = start_query_with(it); tgp.in(TeamData.relationship_label_for(:rosters)); tgp = ConditionBuilder::OrientGraph.build(tgp, team_filters); tgp.to_a.count > 0)  }
        else
          @gp.inV.filter{|playable| playable['@class'] == 'Roster'}.in(TeamData.relationship_label_for(:rosters)).filter {|t| t.get_property('kyck_id') == team_filters[:id]}
        end
        @gp.back(4)

      end

      unless user_filters.empty?
        @gp.as('players').outV
        @gp = ConditionBuilder::OrientGraph.build(@gp, user_filters)
        @gp.back('players')

      end
      @gp
    end

    def self.get_players(obj, opts={}, current=true)
      if opts[:available] && obj.class == Roster
        return self.get_available_players_for_roster(obj, opts)
      elsif opts[:is_open_roster] && obj.class == Organization
        return self.open_organization_players(obj, opts)
      elsif obj.class == Organization
        return self.for_organization(obj, opts)
      end

      offset = opts.fetch(:offset, 0).to_i

      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 if limit > 0
      @gp = player_pipeline_for(obj, opts, current)

      if opts[:order]
        order_dir = (opts[:order_dir] && opts[:order_dir].downcase == 'asc' ? 1 : -1)
        prop = opts[:order]
        @gp.order{|it| if it.a[prop] && !it.a[prop].kind_of?(Fixnum); pr1 = it.a[prop].downcase; pr2 = it.b[prop].downcase; else pr1 = it.a[prop]; pr2 = it.b[prop]; end; (order_dir*(pr1 <=> pr2)).to_java(:int) }
      else
        @gp.orderby ['out.last_name', 'out.first_name'], ['asc', 'asc']
      end

      @gp.range(offset, limit)
      r = @gp.to_a.uniq.map{|c| wrap (c.wrapper)}
    end

    def self.on_other_teams(team, club)
      return [] unless team.official_roster
      player_user_ids = team.official_roster.players.map(&:kyck_id)
      sql = 'select from (traverse out_Team__rosters, in_plays_for, out ' \
        'from (select from (traverse  out_Organization__teams ' \
        "from #{club.id}) where @class='Team' and kyck_id <> " \
        " '#{team.kyck_id}' )) where @class='plays_for' and out.kyck_id " \
        "in #{player_user_ids}"

      execute_sql(sql).map { |p| p.wrapper.model_wrapper }
    end

    def self.for_organization(org, opts={})
      filters = opts[:player_conditions] || {}
      user_filters = opts[:user_conditions] || {}
      team_filters = opts[:team_conditions] ||{}

      sql = "select from (select expand(inE('plays_for')) from (traverse out_Organization__teams, out_Team__rosters from #{org._data.id}) where official=true) where 1=1"

      if filters[:kyck_id]
        sql += " and kyck_id = '#{filters[:kyck_id]}'"
      end

      usrwherecls = ''
      unless user_filters.empty?
        if (user_filters[:last_name_like])
          nm = user_filters.delete(:last_name_like).downcase
          usrwherecls = usrwherecls + " and out.last_name.toLowerCase() like '%#{nm.sql_escape}%'"
        end
        if (user_filters[:first_name_like])
          nm = user_filters.delete(:first_name_like).downcase
          usrwherecls = usrwherecls + " and out.first_name.toLowerCase() like '%#{nm.sql_escape}%'"
        end
        u_filters = {}
        user_filters.each {|k, v| u_filters["out.#{k}"] = v }

        usrwherecls = usrwherecls + ' and '+ConditionBuilder::OrientGraph.sql_build(u_filters) unless u_filters.blank?
        sql = sql + usrwherecls
      end

      unless team_filters.empty?
        sql = 'select from (select expand(outE("plays_for")) from '

        teamsql = "select from (select expand(out('Organization__teams')) from #{org._data.id}) "

        teamwherecls = 'where 1=1'
        if (team_filters[:name_like])
          nm = team_filters.delete(:name_like).downcase
          teamwherecls = teamwherecls + " and name.toLowerCase() like '%#{nm.sql_escape}%'"
        end
        teamwherecls = teamwherecls + ' and ' + ConditionBuilder::OrientGraph.sql_build(team_filters) unless team_filters.blank?

        teamsql = "(traverse in_plays_for, out_Team__rosters from (#{teamsql} #{teamwherecls}))"
        usersql = "(select expand(out) from #{teamsql} where 1=1 #{usrwherecls})"

        sql = sql + usersql + ")"
      end

      opts = {limit: 25, offset: 0}.merge(opts)
      sql = sql + " group by out"
      sql = sql + " order by #{opts[:order]} " if opts[:order]
      sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

      cmd = OrientDB::SQLSynchQuery.new(sql).setFetchPlan('out:1 in:1')
      res = Oriented.graph.command(cmd).execute
      res.map{|c| c.wrapper.model_wrapper}
    end

    def self.open_organization_players(club, opts={})
      sql = 'select from (select expand(inE("plays_for")) from (traverse ' \
        'out_Team__rosters from (select from (traverse ' \
        "out_Organization__teams from #{club._data.id}) where " \
        '@class="Team" and open=true)))'

      last_name = last_name_filter(opts)
      unless last_name.blank?
        sql += " where out.last_name.toLowerCase() like \"%#{last_name.downcase}%\")"
      end
      sql = sql + " order by #{opts[:order]} " if opts[:order]
      sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

      gp = execute_sql(sql) 
      gp.to_a.map{ |p| wrap p.wrapper }
    end

    def self.last_name_filter(opts)
      (opts[:user_conditions] and opts[:user_conditions][:last_name_like]) ||
        (opts[:conditions] and opts[:conditions][:last_name_like])
    end

    def self.get_user_players(user, opts={})
      filters = opts[:conditions] || {}
      conditions = ConditionBuilder::OrientGraph.build(filters)
      whereclause = conditions && conditions[0].length>0 ? ' AND '+conditions[0] : ''

      order =  opts[:order] ? 'ORDER BY x.'+opts[:order] : ''
      offset = opts[:offset] ? ' SKIP '+opts[:offset].to_s : ''
      limit = opts[:limit] ? ' LIMIT '+opts[:limit].to_s : ''

      dontfollow = ['_all']
      dontfollow << '.*previous' if current
    end

    def self.get_players_summary(obj, opts={})
      begin
        filters = opts[:conditions] || {}
        gp = start_query_with(obj)

        grouped_res = {}
        key_function = KyckPipeFunction.new
        key_function.send(:define_singleton_method, :compute) { |it|
          "#{it['status']}"
        }
        val_function = KyckPipeFunction.new
        val_function.send(:define_singleton_method, :compute) { |it| it }
        gp.group_count(grouped_res, key_function)

        gp.to_a
      rescue Exception=>e
        puts e.inspect
      end
      grouped_res
    end

    def self.get_available_players_for_roster(obj, opts = {})
      return open_organization_players(obj.organization, opts) if obj.official?
      player_rel_label = UserData.relationship_label_for(:plays_for)
      roster_rel_label = TeamData.relationship_label_for(:rosters)
      team_rel_label = OrganizationData.relationship_label_for(:teams)
      user_filters = opts[:conditions] || {}
      player_filters = opts[:player_conditions] || {}

      current_players = []

      @gp = start_query_with(obj)
      @gp.in(player_rel_label)
      @gp.store(current_players).optional(2).in(roster_rel_label)

      @gp.out(roster_rel_label).filter { |r| r['official'] == true }
      @gp.inE(player_rel_label) # players on official roster

      @gp = ConditionBuilder::OrientGraph.build(@gp, player_filters)
      @gp.outV
      back = 2
      unless user_filters.empty?
        back = 3
        @gp = ConditionBuilder::OrientGraph.build(@gp, user_filters)
      end
      @gp.except(current_players).back(back)
      handle_query_options(@gp, opts)
      @gp.to_a.uniq.map { |c| wrap(c.wrapper) }
    end

    def self.get_invalid_player_cnt(team, attrs = nil)
      return 0 if attrs.blank?
      wherearr = []
      if attrs[:birthdate]
        wherearr << "birthdate < date('#{attrs[:birthdate]}', 'yyyy-MM-dd')"
      end
      wherearr << "gender <> '#{attrs[:gender]}'" if attrs[:gender]

      return 0 unless wherearr.count

      wherecls = '( ' + wherearr.join(' OR ') + ' )'
      sql = 'select count(*) from (traverse in("plays_for"),  '\
            'out_Team__rosters[official=true] from #' + team.id + ') '\
            'where @class="User" and ' + wherecls
      res = execute_sql(sql).to_a.first
      res && res['count'] || 0
    end

    private

    def self.user_attributes_provided?(conditions)
      conditions.keys.each do |attr|
        return true if attr =~ USER_ATTRIBUTES_REGEX
      end
    end

    def self.join_conditions(conditions)
      user_parms = conditions.select { |k| k =~ USER_ATTRIBUTES_REGEX }
      ups = {}
      parms = conditions.diff(user_parms)
      user_parms.each_pair do |k, v|
        ups["users.#{k}"] = v
      end
      parms.merge(ups)
    end
  end
end

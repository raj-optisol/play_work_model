module UserRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class User

  def self.find_by_email(email)
    find_by_attrs(conditions: {email: email}).first
  rescue
    nil
  end

  def self.wrapper(user)
    wrap user
  end

  def self.sb_admins
    sql = 'select expand(distinct(out)) from (traverse in_staff_for ' \
      'from state) where @class="staff_for" and role="Admin"'
    cmd = OrientDB::SQLSynchQuery.new(sql)
    results = Oriented.graph.command(cmd).execute
    results.map {|o| wrap o.wrapper}
  end

  def self.find_for_account(account)
    find_by_kyck_id(account.kyck_id.to_s) || find_by_email(account.email)
  end

  def self.find_or_create_for_account(account, attrs)
    attrs = {kyck_id: account.kyck_id.to_s}.merge(attrs)

    # This doesn't work....dammit
    #u = UserData.get_or_create(attrs)

    u = find_for_account(account)

    return u if u
    u = User.build(attrs)
    u = UserRepository.persist(u)
    u
  end

  def self.get_recipients_for_obj(requestor, obj, attrs={})

    @gp = KyckPipeline.new(Oriented.graph)
    @gp2 = KyckPipeline.new(Oriented.graph)
    @gp3 = KyckPipeline.new(Oriented.graph)
    @gp.start(obj._data.__java_obj).copy_split(@gp2.out('Team__rosters').in('plays_for'),
                                               @gp3.in('staff_for')).fairMerge.dedup.gather{|it|
      if it.include?(requestor._data.__java_obj)
        it
      elsif requestor.can_manage?(obj, [ PermissionSet::MANAGE_TEAM ])
        it
      else
        raise KyckRegistrar::PermissionsError
      end

    }.scatter.filter{|it| it['kyck_id'] != requestor.kyck_id}
                                               ret = @gp.to_a


                                               if ret.length>0
                                                 # ret = ret[0]

                                                 kyck_ids = ret.map{|s| s['kyck_id'] }
                                                 settings = UserSettingsRepository.find_by_attrs({user_id_in:kyck_ids})
                                                 newobj = settings.inject({}) {|h, obj| h[obj.user_id.to_s] = obj.settings; h }

                                                 ret = ret.map{|s|
                                                   us = newobj[s['kyck_id']]

                                                   u = {kyck_id:s['kyck_id'], name: s['first_name']+' '+s['last_name']}

                                                   # u[:to] = true if s['kyck_ikyck_id== obj.kyck_id.to_s
                                                   if us
                                                     u[:email] = s['email'] if us['notify_email'] == 'on'
                                                     u[:phone_number] = s['phone_number'] if us['notify_text'] == 'on' && s['phone_number_validated']
                                                   end
                                                   u
                                                 } if ret
                                               end
                                               ret

  end

  def self.get_users_for_team(team_id, conditions={})
    team = OrganizationRepository::TeamRepository.find(kyck_id: team_id)

    gp = start_query_with(team._data)
    player_pipeline = start_query_with(team._data)
    player_pipeline.out(TeamData.relationship_label_for(:rosters)).in('plays_for')

    staff_pipeline = start_query_with(team._data)
    staff_pipeline.in('staff_for')

    gp.copy_split(player_pipeline, staff_pipeline).fair_merge.dedup
    unless conditions.empty?
      gp = ConditionBuilder::OrientGraph.build(gp,conditions)
    end

    gp.to_a.map { |u| wrap u.wrapper }

  end

  def self.get_playable_users(obj, opts={})
    offset = opts.fetch(:offset, 0).to_i
    limit = opts.fetch(:limit, 30).to_i+offset
    limit -= 1 unless limit == 0

    user_filters = opts[:conditions] || {}
    player_filters = opts[:player_conditions] ||{}

    @gp = start_query_with(obj._data)
    @gp.inE(player_rel_label)
    @gp = ConditionBuilder::OrientGraph.build(@gp, player_filters)

    @gp.outV

    @gp = ConditionBuilder::OrientGraph.build(@gp, user_filters)

    if opts[:order]
      order_dir = (opts[:order_dir] && opts[:order_dir].downcase == 'asc' ? 1 : -1)
      prop = opts[:order]
      @gp.order{|it| if it.a[prop] && !it.a[prop].kind_of?(Fixnum); pr1 = it.a[prop].downcase; pr2 = it.b[prop].downcase; else pr1 = it.a[prop]; pr2 = it.b[prop]; end; (order_dir*(pr1 <=> pr2)).to_java(:int) }
    end

    @gp.range(offset, limit)
    r = @gp.to_a.uniq.map{|c| wrap (c.wrapper)}
  end

  def self.get_players_for_organization(org, opts={})
    offset = opts.fetch(:offset, 0).to_i
    limit = opts.fetch(:limit, 30).to_i+offset
    limit -= 1 unless limit == 0

    user_filters = opts[:conditions] || {}
    player_filters = opts[:player_conditions] ||{}
    season_filters = opts[:season_conditions] || {}
    season_default_dates = {start_date_lte: Time.now.utc.to_i, end_date_gte: Time.now.utc.to_i}
    season_filters = season_default_dates.merge(season_filters);

    @gp = start_query_with(org._data)

    @gp.inE(player_rel_label)
    @gp = ConditionBuilder::OrientGraph.build(@gp, player_filters)

    @gp.outV
    @gp = ConditionBuilder::OrientGraph.build(@gp, user_filters)

    if opts[:order]
      order_dir = (opts[:order_dir] && opts[:order_dir].downcase == 'asc' ? 1 : -1)
      prop = opts[:order]
      @gp.order do |it|
        if it.a[prop] && !it.a[prop].kind_of?(Fixnum)
          pr1 = it.a[prop].downcase
          pr2 = it.b[prop].downcase
        else
          pr1 = it.a[prop]
          pr2 = it.b[prop]
        end
        (order_dir * (pr1 <=> pr2)).to_java(:int)
      end
    end

    @gp.range(offset, limit)
    @gp.to_a.uniq.map { |c| wrap(c.wrapper) }
  end

  def self.get_player_summary_for_organization(obj)
    begin
      grouped_res = {}
      sql = 'select from (select expand(in("plays_for")) from ' \
        '(traverse out_Organization__teams, out_Team__rosters ' \
        "from #{obj._data.id})) group by kyck_id"

      gp = start_query_with(execute_sql(sql))

      key_function = KyckPipeFunction.new
      key_function.send(:define_singleton_method, :compute) do |it|
        birthdate = it['birthdate']
        if !birthdate
          'Undefined:'
        elsif birthdate.after(UserRepository.below11)
          'U-11 & Below:'
        elsif birthdate.after(UserRepository.below19)
          'U-12 to U-19:'
        else
          'U-20 & Above:'
        end
      end
      gp.group_count(grouped_res, key_function)
      gp.iterate
    rescue => e
      puts e.inspect
    end
    grouped_res
  end

  def self.get_available_players_for_team(obj, opts = {})
    user_filters = opts[:conditions] || {}
    player_filters = opts[:player_conditions] || {}

    current_players = []
    @gp = start_query_with(obj._data)
    @gp.out(roster_rel_label).filter { |r| r['official'] == true }
    @gp.in(player_rel_label).store(current_players).back(4)
    @gp.in(team_rel_label).inE(player_rel_label)
    @gp = ConditionBuilder::OrientGraph.build(@gp, player_filters)

    @gp.outV

    @gp = ConditionBuilder::OrientGraph.build(
      @gp,
      user_filters).except(current_players)

    handle_query_options(@gp, opts)
    @gp.to_a.uniq.map { |c| wrap(c.wrapper) }
  end

  def self.below11
    Java::JavaUtil::Date.new(
      (Date.today - 12.years - 1.day).to_time.to_i * 1000)
  end

  def self.below19
    Java::JavaUtil::Date.new(
      (Date.today - 19.years - 1.day).to_time.to_i * 1000)
  end

  def player_rel_label
    UserData.relationship_label_for(:plays_for)
  end

  def roster_rel_label
    TeamData.relationship_label_for(:rosters)
  end

  def team_rel_label
    OrganizationData.relationship_label_for(:teams)
  end
end

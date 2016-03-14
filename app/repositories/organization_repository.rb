# encoding: UTF-8
module OrganizationRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class Organization

  def self.find_by_email(email)
    find_by_attrs(conditions: {email: email})
  end

  def self.find_by_name(name)
    find_by_attrs(conditions: {name: name})
  end

  def self.create_staff org, attrs
    staff = StaffRepository.create_staff(org, attrs)
    data(org).reload
    staff
  end

  def self.persist_staff org, staff
    StaffRepository.persist staff
  end

  def self.destroy_staff org, staff_id
    StaffRepository.destroy_staff(org, id)
    data(org).reload
  end

  def self.get_associated_teams(user, season, permissions)
    if user.kind =='admin'
      opts = {} #{'order'=>'name', 'offset'=>'0', 'limit'=>'2'}
      filters = {} #{name_like:"s"} #opts['conditions'] || {}

      conditions = ConditionBuilder::Graph.build(filters)
      whereclause = conditions && conditions[0].length>0 ? " and "+conditions[0] : ""

      order =  opts['order'] ? "ORDER BY x."+opts['order'] : ""
      offset = opts['offset'] ? " SKIP "+opts['offset'] : ""
      limit = opts['limit'] ? " LIMIT "+opts['limit'] : ""
    else
      get_associated_items_for_obj_with_permissions(user, org.id, 'TeamData', permissions)
    end
  end

  def self.get_orgs_for_user(user, opts={}, permissions=[])
    offset = opts.fetch(:offset, 0).to_i
    limit = opts.fetch(:limit, 30).to_i+offset
    limit -= 1 unless limit == 0

    filters = opts[:conditions] || {}

    if permissions.length > 0
      @gp = start_query_with(user)
      t = Java::ComTinkerpopPipesUtilStructures::Table.new
      @gp.outE("staff_for").as("staff").filter{|it|
        (it["permission_sets"].to_a & permissions).any?
      }.as("s").inV.filter{|it| it["@class"]=='Organization'}.as("org")
      @gp = ConditionBuilder::OrientGraph.build(@gp, filters)
      @gp.back('s').property('permission_sets').as("perms").table(t, ['perms', 'org']).cap
      r = @gp.to_a.first
      result = r.collect{|c|  o = wrap (c.column("org").wrapper); o.send("permissions=", Set.new(c.column("perms"))); o  } if r
    else
      sql = "select from (traverse in_Team__rosters, in_Organization__teams from (traverse in from (traverse out_plays_for, out_staff_for from #{user._data.id}))) where @class='Organization'"
      cmd = OrientDB::SQLSynchQuery.new(sql)
      results = Oriented.graph.command(cmd).execute
      results.map {|o| wrap o.wrapper}
    end
  end

  def self.get_orgs_for_competition(competition_id, opts = {})
    return [] if opts['name_like'].blank?

    sql = 'select from (traverse in_CompetitionEntry__competition, ' \
      'out_CompetitionEntry__team, in_Organization__teams ' \
      'from (select from Competition ' \
      "where kyck_id=#{ActiveRecord::Base.sanitize(competition_id)})) " \
      'where @class=\'Organization\' and name.toLowerCase() >= ' \
      "#{ActiveRecord::Base.sanitize(opts['name_like'].downcase + " ")}  and " \
      'name.toLowerCase() < ' \
      "#{ActiveRecord::Base.sanitize(opts['name_like'].downcase + "z")} order by " \
      'name asc'

    cmd = OrientDB::SQLSynchQuery.new(sql)
    results = Oriented.graph.command(cmd).execute
    results.map { |o| wrap o.wrapper }
  end

  def self.get_org_and_staff(user, org_id)
    return [wrap(self.find(org_id)), PermissionObject.new(user)] if user.kind=='admin'
  end

  def self.get_organization_for_user (org_id, user_id, permissions=[])
    return self.find(org_id) if permissions.empty?
    return wrap obj if obj
  end

  def self.get_organization_for_obj(obj)
    sql = "select from (traverse in_Organization__teams  from #{obj._data.id}) where @class='Organization'"
    cmd = OrientDB::SQLSynchQuery.new(sql)
    obj = Oriented.graph.command(cmd).execute.collect{|t| t.wrapper.model_wrapper}.first
  end

  def self.get_sanctioned_objects(sanctioning_body, options = {}, state = nil)
    s = nil
    begin
      filters = options[:conditions] || {}
      s_filters = options[:sanction_conditions] || {}
      query = start_query_with(sanctioning_body)
      if state
        query = query.out(SanctioningBodyData.relationship_label_for(:states)).
          filter { |it| it["kyck_id"] == state_id }.
          in(StateData.relationship_label_for(:organizations))

        query = ConditionBuilder::OrientGraph.build(query, filters)
      else
        query = query.outE(SanctioningBodyData.relationship_label_for(:sanctions)).
          as('sanction')
        query = ConditionBuilder::OrientGraph.build(query, s_filters)
        query.inV
        query = ConditionBuilder::OrientGraph.build(query, filters)
        query.back('sanction')

      end

      s = query.to_a.map { |t| wrap t.wrapper }
    rescue Exception=>e
      puts e.inspect
    end
    s
  end

  def self.wrapper(org)
    wrap org
  end

  def self.get_organizations_sanctioned_by(sanctioning_body, options = {},
                                           state = nil)
    filters = options[:conditions] || {}

    cmd = OrientDB::SQLCommand.new(
      sql_for_organizations_sanctioned_by(sanctioning_body, filters, options)
    )
    return Oriented.graph.command(cmd).execute.map { |o| wrap o.wrapper }

    if state
      query = query.filter { |it| it['state'] == state.abbr }
    end
    query = handle_query_options(query, options)

    query.to_a.map { |t| (wrap t.wrapper) }
  end

  def self.sql_for_organizations_sanctioned_by(sb, filters, options)
    sql = 'select from (traverse out_sanctions,in from ' \
      "#{sb._data.id}) where @class='Organization'"
    sql = "#{sql} and name.toLowerCase() >= '#{filters[:name_like].downcase} '" \
       'and name.toLowerCase() ' \
       "< '#{filters[:name_like].downcase}z'" if filters[:name_like]

    opts = { order: 'id desc', limit: 25, offset: 0 }.merge(options)

    sql = "#{sql} order by #{opts[:order]} limit #{opts[:limit]} " \
      "offset #{opts[:offset]}"
    puts sql
    sql
  end
end

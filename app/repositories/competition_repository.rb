module CompetitionRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class Competition

  def self.get_card_processing_competitions
    sql = "select expand(in) from sanctions where in.@class='Competition' and can_process_cards=true"
    cmd = OrientDB::SQLSynchQuery.new(sql)
    Oriented.graph.command(cmd).execute.collect{|c| c.wrapper.model_wrapper}
  end

  def self.get_associated_competitions(user, obj, attrs={}, permissions=[])
    if user.kind =='admin'

      opts = {} #{'order'=>'name', 'offset'=>'0', 'limit'=>'2'}
      filters = {} #{name_like:"s"} #opts['conditions'] || {}

      conditions = ConditionBuilder::Graph.build(filters)
      whereclause = conditions && conditions[0].length>0 ? " and "+conditions[0] : ""

      order =  opts['order'] ? "ORDER BY x."+opts['order'] : ""
      offset = opts['offset'] ? " SKIP "+opts['offset'] : ""
      limit = opts['limit'] ? " LIMIT "+opts['limit'] : ""

    else
      OrganizationRepository.get_associated_items_for_obj_with_permissions(user, obj.id, 'CompetitionData', permissions)
    end
  end

  def self.get_user_competitions(user, opts={}, permissions=[])
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
      sql = "select from (traverse in from (traverse out_plays_for, out_staff_for from #{user._data.id})) where @class='Competition'"
      cmd = OrientDB::SQLSynchQuery.new(sql)
      results = Oriented.graph.command(cmd).execute
      results.map { |o| wrap o.wrapper }
    end
  end

  def self.get_team_competitions(team, opts={})
    gp = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
    gp.start(team._data.__java_obj)

    team_roster_label = TeamData.relationship_label_for(:rosters)
    div_roster_label = DivisionData.relationship_label_for(:rosters)

    gp.out(team_roster_label).out(div_roster_label).in.filter{|it| it.label == "Competition"}
    gp = ConditionBuilder::OrientGraph.build(gp, opts[:conditions]) if opts[:conditions]

    gp.to_a.map {|c|wrap c.wrapper}

  end


  def self.get_available_competitions(obj=nil, opts={}, user=nil)

    sql = "select from (select from competition where open=true) let $cfor = (select @rid from $parent.$current.in_CompetitionEntry__competition where out_CompetitionEntry_team.@rid =  #{obj._data.id}) where $cfor.size() = 0"

    filters = ( opts[:conditions] || {} ).with_indifferent_access
    filters.each_pair do |k,v|
      filters.delete(k) if v.blank?
    end

    if (filters[:name_like])
      nm = filters.delete(:name_like).downcase
      sql = sql + " and name.toLowerCase() like '%#{nm}%'"
    end

    sql = sql + " and "+ConditionBuilder::OrientGraph.sql_build(filters) unless filters.blank?
    opts = {limit: 25, offset: 0}.merge(opts)
    sql = sql + " order by #{opts[:order]} " if opts[:order]
    sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

    # puts sql
    cmd = OrientDB::SQLSynchQuery.new(sql).setFetchPlan("out_Competition__locations:1")
    Oriented.graph.command(cmd).execute.collect{|t| t.wrapper.model_wrapper}

  end

  def self.remove_team_from_competition(team, comp)
    begin
      team_roster_label = TeamData.relationship_label_for(:rosters)
      div_roster_label = DivisionData.relationship_label_for(:rosters)

      gp = start_query_with(team._data)
      gp.out(team_roster_label).inE(div_roster_label).as("comp_roster").outV.in.filter{|it| it.id.toString() == comp.id}.back("comp_roster").remove()

      self.persist comp
    rescue Exception=>e
      puts e.inspect
    end
  end

  class DivisionRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Division

    def self.get_divisions_for_competition(user, comp, attrs={}, permissions=[])
      get_items(comp, 'Competition__divisions', attrs, user, permissions)
    end
  end
end

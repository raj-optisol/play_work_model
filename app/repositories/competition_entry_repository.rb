require_relative 'condition_builder'

module CompetitionEntryRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class CompetitionEntry

  def self.find_by_status(status)
    find_by_attrs(conditions: {status: status})
  end

  def self.find_entries_targeting_obj(obj, opts)

    sql = "select from (traverse in_CompetitionEntry__competition, in_CompetitionEntry__division, in_CompetitionEntry__roster, in_CompetitionEntry__team from  #{obj._data.id}) where @class='CompetitionEntry'"

    filters = opts[:conditions] || {}

    unless filters.empty?
      ce_filter_sql = ConditionBuilder::OrientGraph.sql_build(filters)
      sql = sql + " and #{ce_filter_sql}" unless ce_filter_sql.blank?
    end

    competition_filters = opts[:competition_conditions] || {}
    division_filters = opts[:division_conditions] || {}
    team_filters = opts[:team_conditions] || {}
    roster_filters = opts[:roster_conditions] || {}
    organization_filters = opts[:organization_conditions] || {}

    sql = "#{sql} #{build_sql_filters(competition_filters, 'out_CompetitionEntry__competition')}" unless competition_filters.empty?
    sql = "#{sql} #{build_sql_filters(division_filters, 'out_CompetitionEntry__division')}" unless division_filters.empty?
    sql = "#{sql} #{build_sql_filters(team_filters, 'out_CompetitionEntry__team')}" unless team_filters.empty?
    sql = "#{sql} #{build_sql_filters(roster_filters, 'out_CompetitionEntry__roster')}" unless roster_filters.empty?
    sql = "#{sql} and out_CompetitionEntry__team.in_Organization__teams.kyck_id = '#{organization_filters[:kyck_id]}'" unless organization_filters.empty? || organization_filters[:kyck_id].blank?


    opts = {limit: 25, offset: 0}.merge(opts)
    sql = sql + " order by #{opts[:order]} " if opts[:order]
    sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

    cmd = OrientDB::SQLSynchQuery.new(sql)
    gp = nil
    bm = Benchmark.measure do
    gp = Oriented.graph.command(cmd).execute

    end

    gp.to_a.collect{|c| wrap c.wrapper }
  end

  def self.build_sql_filters(filters, prepend_label)
      filter_sql = ""
      if (filters[:name_like])
        nm = filters.delete(:name_like).downcase
        filter_sql = filter_sql + " and #{prepend_label}.name.toLowerCase() like '%#{nm}%'"
      end
      new_filters = filters.map { |k,v| {"#{prepend_label}.#{k}" => v} }.reduce({}, :merge)
      s = ConditionBuilder::OrientGraph.sql_build(new_filters)
      filter_sql = "#{filter_sql} and #{s}" unless s.blank?
      filter_sql
  end

  def self.find_requests_targeting_competition(competition, opts={})

    division_label = CompetitionData.relationship_label_for(:divisions)
    target_label = DivisionData.relationship_label_for(:join_requests)

    opts = opts.symbolize_keys
    filters = opts[:conditions] || {}
    division_filters = opts[:division_conditions] || {}

    gp = start_query_with(competition)
    gp.out(division_label)

    gp = ConditionBuilder::OrientGraph.build(gp, division_filters)  unless division_filters.empty?

    gp.in(target_label)
    gp = ConditionBuilder::OrientGraph.build(gp, filters) unless filters.empty?

    gp = handle_query_options(gp, opts)
    gp.to_a.collect{|c| wrap c.wrapper }

  end

  def self.find_requests_on_behalf_of_team(team, opts)

    roster_label = TeamData.relationship_label_for(:rosters)
    from_label = RosterData.relationship_label_for(:play_request)

    opts = opts.symbolize_keys
    filters = opts[:conditions] || {}
    roster_filters = opts[:roster_conditions] || {}

    gp = start_query_with(team)
    gp.out(roster_label)

    gp = ConditionBuilder::OrientGraph.build(gp, roster_filters)  unless roster_filters.empty?

    gp.out(from_label)
    gp = ConditionBuilder::OrientGraph.build(gp, filters) unless filters.empty?

    gp = handle_query_options(gp, opts)
    gp.to_a.collect{|c| wrap c.wrapper }

  end


  def self.get_pending_request(org)
    Rails.logger.info(org.inspect);
    return org.play_request.select {|req| req.status == :pending || req.status == :pending_payment }.first if org.play_request
  end

  #default seconds = 30 day month
  def self.denied_within_time(org, seconds=2592000.0)
    Rails.logger.info "** denied"
    Rails.logger.info org.sanctioning_requests.inspect
    res = org.sanctioning_requests.select {|req| req.status == :denied }
    res.select do |req|
      ( (Time.now.utc.to_i - req.updated_at) < seconds )
    end
  end
end





module CardRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  extend CommonODBRepository
  set_model_class Card

  def self.duplicate_cards(card)
    lookup_hash = card.try(:duplicate_lookup_hash)
    return [] if lookup_hash.nil? || lookup_hash.blank?

    sql = "select from Card where kyck_id <> '#{card.kyck_id}' " \
    "and duplicate_lookup_hash = '#{lookup_hash}' " \
    "and kind = '#{card.kind.to_s.downcase}' " \
    "and status not in ['released', 'expired']"

    execute_sql(sql).map { |c| wrap c.wrapper }
  end

  def self.duplicate_cards_for_card(card, conditions = {})
    sql = "select from Card where kyck_id <> '#{card.kyck_id}' " \
    "and duplicate_lookup_hash = '#{card.duplicate_lookup_hash}'"

    conds = build_conditions(conditions)
    sql += " and #{conds}" unless conds.blank?

    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.cards_for_user(user, conditions = {})
    sql = "select from (traverse in_Card__carded_user from #{user.id}) "\
    'where @class = \'Card\''

    conds = build_conditions(conditions[:card_conditions])
    sql += " and #{conds}" unless conds.blank?

    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.find_for_product(product, user, org, sb)
    sql = "select from (traverse in_Card__carded_user from #{user.id}) "\
    "where @class = 'Card' and kind = '#{product.card_type.to_s.downcase}' "\
    "and out_Card__sanctioning_body.kyck_id = '#{sb.kyck_id}' "\
    "and out_Card__carded_for.kyck_id = '#{org.kyck_id}' limit 1"

    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }.first
  end

  def self.create_for_product(attrs, user, org, sb, comp = nil)
    card = Card.build(attrs)
    card.reset

    card.carded_user = user._data
    card.carded_for = org._data
    card.sanctioning_body = sb._data
    card._data.processor = comp._data if comp

    card
  end

  def self.for_sanctioning_body_and_organization(sb, org, options={})
    options[:organization_conditions] ||= {}
    options[:organization_conditions][:organization_id] = org.kyck_id
    self.get_cards(sb, options)
  end

  def self.approved_for_user(user)
    sql = 'select expand(in_Card__carded_user) from User ' +
      "where @rid=#{user.id} and in_Card__carded_user.status='approved'"
    cmd = OrientDB::SQLSynchQuery.new sql
    Oriented.graph.command(cmd).execute.collect { |c| wrap c.wrapper }
  end

  def self.approved_player_for_user_and_org(user, org)
    sql = "select from (traverse in_Card__carded_user from #{user._data.id})"\
      ' where @class="Card" and status="approved" ' \
      "and kind='player' and " \
      "out_Card__carded_for.@rid=#{org.id}"
    cmd = OrientDB::SQLSynchQuery.new sql
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.new_for_user(user)
    sql = 'select expand(in_Card__carded_user) from User ' +
      "where @rid=#{user.id} and in_Card__carded_user.status='new'"
    cmd = OrientDB::SQLSynchQuery.new sql
    Oriented.graph.command(cmd).execute.collect { |c| wrap c.wrapper }
  end

  def self.for_sanctioning_body_and_competition(sb, competition, options={})

    # Add sanctioning body id to the filter.
    options[:card_conditions] ||= {}

    # Generate the query string.
    sql = generate_competition_cards_query(competition, options) + build_sql_options(options)
    puts sql

    #puts sql

    cmd = OrientDB::SQLSynchQuery.new(sql)
    gp = nil
    gp = Oriented.graph.command(cmd).execute

    gp.to_a.collect{|c| wrap c.wrapper }
  end

  def self.approved_in_span(start_date, end_date, limit = nil, offset = nil)
    sql = 'select from Card where approved_on >= ' +
      "#{start_date.to_time.utc.midnight.to_i} and " +
      "approved_on < #{end_date.to_time.utc.midnight.to_i}"
    sql = sql + " LIMIT #{limit}" if limit
    sql = sql + " OFFSET #{offset}" if offset
    cmd = OrientDB::SQLSynchQuery.new sql
    Oriented.graph.command(cmd).execute.collect { |c| wrap c.wrapper }
  end


  def self.generate_competition_cards_query(competition, options)
    # This is to avoid checking for options every time.
    return unless options

    # Store the card kind for convenience.
    card_kind = options[:card_conditions][:kind] || "player"
    team_ids = []

    # First check if I have a team kyck_id, if I do then traverse through the
    # team since it's faster.
    if options[:team_conditions] && options[:team_conditions][:kyck_id]

       # Set the query depending on the card type, default to player.
      sql = "select from (traverse in_staff_for, out, in_Card__carded_user from (select from team where #{build_sql_filters(options[:team_conditions])})) where @class = 'Card'" if card_kind == "staff"
      sql ||= "select from (traverse in_plays_for, out, in_Card__carded_user from (select from (traverse out_Team__rosters from (select from team where #{build_sql_filters(options[:team_conditions])})) where @class = 'Roster' and in_CompetitionEntry__roster is not null and in_CompetitionEntry__roster.out_CompetitionEntry__competition.kyck_id = '#{competition.kyck_id}')) where @class = 'Card'"

      # Additional conditions.
      sql << " and #{build_sql_filters(options[:user_conditions])}" if options[:user_conditions]
      sql << " and #{build_sql_filters(options[:card_conditions])}"
      sql << " and #{build_sql_filters(options[:organization_conditions], 'out_Card__carded_for')}" if options[:organization_conditions]
      sql << ' group by out_Card__carded_user.@rid' if card_kind == 'staff'

      # We are done!
      return sql
    else
      competition.entries.each do |entry|
        team_ids << entry.try(:team).try(:kyck_id) if entry.try(:team).present?
      end

      # Set the query depending on the card type, default to player.
      sql = "select from (traverse in_staff_for, out, in_Card__carded_user from (select from team where kyck_id IN (#{team_ids}))) where @class = 'Card'" if card_kind == "staff"
      sql ||= "select from (traverse in_plays_for, out, in_Card__carded_user from (select from (traverse out_Team__rosters from (select from team where kyck_id IN (#{team_ids}))) where @class = 'Roster' and in_CompetitionEntry__roster is not null and in_CompetitionEntry__roster.out_CompetitionEntry__competition.kyck_id = '#{competition.kyck_id}')) where @class = 'Card'"
     
      # Additional conditions.
      sql << " and #{build_sql_filters(options[:user_conditions])}" if options[:user_conditions]
      sql << " and #{build_sql_filters(options[:card_conditions])}"
      sql << " and #{build_sql_filters(options[:organization_conditions], 'out_Card__carded_for')}" if options[:organization_conditions]
      sql << ' group by out_Card__carded_user.@rid' if card_kind == 'staff'

      # We are done!
      return sql
    end
      # This the old code for find players by competition
      # Set the query depending on the card type, default to player.
      #sql ||= "select from (traverse in_Card__processor from #{competition._data.id}) where @class = 'Card'"

      #options[:card_conditions].merge!(options[:user_conditions]) if options[:user_conditions]
      # Additional conditions.
      #sql << " and #{build_sql_filters(options[:card_conditions])}"
      #sql << " and #{build_sql_filters(options[:organization_conditions], 'out_Card__carded_for')}" if options[:organization_conditions]

      # We are done!
      # return sql
  end

  def self.for_user_and_sanctioning_body(user, sb, options)
    gp = start_query_with(user)
    gp.in(CardData.relationship_label_for(:carded_user))
    gp = filter_cards(gp, options)
    gp.out(CardData.relationship_label_for(:sanctioning_body)).filter{|s| s['kyck_id'] == sb.kyck_id }.back(2)
    gp = filter_organizations(gp, options)
    gp = handle_query_options(gp, options)
    gp.collect {|r| wrap r.wrapper}
  end



  def self.for_sanctioning_body(sb, options={})
    self.get_cards(sb, options)
  end

  def self.for_sanctioning_body_sql(sb, options={})
    opts = {order: "id desc", limit: 25, offset: 0}.merge(options)

    sql = "select from (select  expand(in('Card__carded_user')) from user where "
    sql << ConditionBuilder::OrientGraph.sql_build(options[:user_conditions])
    sql << " and in_Card__carded_user is not null) where "
    sql << ConditionBuilder::OrientGraph.sql_build(options[:card_conditions]) + " and " if options[:card_conditions] && options[:card_conditions].any?
    sql << ConditionBuilder::OrientGraph.sql_build(options[:organization_conditions]) + " and " if options[:organization_conditions] && options[:organization_conditions].any?
    sql << " out_Card__sanctioning_body.kyck_id='#{sb.kyck_id}'"


    sql << " order by #{opts[:order]} limit #{opts[:limit]} offset #{opts[:offset]}"

    execute_sql(sql)
  end

  def self.sanctioning_body_pipeline(sb)
    gp = start_query_with(sb._data)

    # Get the SB cards
    gp.in(CardData.relationship_label_for(:sanctioning_body))
    gp
  end

  def self.competition_pipeline(comp)
    gp = start_query_with(comp._data)

    # Get the SB cards
    gp.in(CardData.relationship_label_for(:processor))
    gp
  end

  def self.organization_pipeline(gp, org)
    # Get the Orgs for the cards
    gp.out(CardData.relationship_label_for(:carded_for))

    # Only get the cards for the passed in org
    gp.filter {|it| it.get_property("kyck_id") == org.kyck_id}

    # Make sure to return the cards
    gp.back(2)
    gp
  end


  def self.filter_cards(gp, options)
    card_filters = options[:card_conditions] || {}
    team_filters = options[:team_conditions] || {}
    gp.as("cards")
    unless card_filters.empty?
      gp = ConditionBuilder::OrientGraph.build(gp, card_filters)
    end
    unless team_filters.empty?
      gp.out(CardData.relationship_label_for(:carded_user))


      gp1 = KyckPipeline.new(Oriented.graph)
      gp2 = KyckPipeline.new(Oriented.graph)
      gp.copy_split(
        gp1._().out(UserData.relationship_label_for(:plays_for)).filter {|it| it["@class"] == "Roster"}.in(TeamData.relationship_label_for(:rosters)),
        gp2._().out(UserData.relationship_label_for(:staff_for)).filter {|it| it["@class"] == "Team"}
      ).fair_merge

      gp = ConditionBuilder::OrientGraph.build(gp, team_filters)
      gp.back("cards")
    end
    gp
  end

  def self.filter_organizations(gp, options)
    org_filters = options[:organization_conditions] || {}
    unless org_filters.empty?

      if org_filters['organization_id']
        gp.out(CardData.relationship_label_for(:carded_for)).filter{|o| o['kyck_id'] == org_filters['organization_id']}.back(2)
      end

      if org_filters[:state]
        gp.out(CardData.relationship_label_for(:carded_for)).out(OrganizationData.relationship_label_for(:locations))
        gp = ConditionBuilder::OrientGraph.build(gp, org_filters)
        gp.back(3)
      end

    end
    gp
  end

  def self.filter_users(gp, options)
    user_filters = ( options[:user_conditions] || {} ).with_indifferent_access
    unless user_filters.empty?
      gp.as('cards').out(CardData.relationship_label_for(:carded_user))
      gp = ConditionBuilder::OrientGraph.build(gp, user_filters)
      gp.back('cards')
    end
    gp
  end

  def self.filter_teams(gp, options)
    team_filters = options[:team_conditions] || {}
    unless team_filters.empty?
      gp.as('cards').out(CardData.relationship_label_for(:carded_user))
      gp.out("plays_for").filter {|it| it["@class"] == 'Roster'}
      gp.in(TeamData.relationship_label_for(:rosters))
      gp = ConditionBuilder::OrientGraph.build(gp, team_filters)

      gp.back('cards')
    end
    gp
  end

  def self.get_cards_for_order(order_id, options={})
    options[:conditions] = options[:conditions] || {}
    options[:conditions][:order_id] = order_id
    self.find_by_attrs(options)
  end

  def self.cards_for_order(order, conditions = {})
    card_ids = order.order_items.map(&:item_id).compact
    return [] if card_ids.empty?
    sql = "select from Card where kyck_id in ['#{card_ids.join('\', \'')}']"
    sql += "AND status NOT IN ['inactive']"
    execute_command_with_defaults(sql, conditions)
  end

  def self.execute_command_with_defaults(sql, conditions, operator = 'and')
    conds = build_conditions(conditions[:card_conditions])
    sql += " #{operator} #{conds}" unless conds.blank?

    opts = {limit: 25, offset: 0}.merge(conditions)
    sql += " limit #{opts[:limit]} offset #{opts[:offset]}"

    execute_sql(sql).map { |c| wrap c.wrapper }
  end

  def self.update_expired_cards
    sql = "update Card set status='expired' where expires_on < #{Time.now.utc.to_i} and status <> 'expired' TIMEOUT 120000"
    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute
  end

  def self.get_cards(sb, options={})
    card_params = CardQueryParameters.new(options)
    sql = card_params.sql

    opts = {limit: 25, offset: 0}.merge(options)
    dir = opts.fetch(:order_dir, 'asc')
    sql = sql + " order by #{opts[:order]} #{dir} " if opts[:order]
    sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

    res = execute_sql(sql).to_a
    res.map{ |t| t.wrapper.model_wrapper }
  end

  def self.for_organization_and_users(org, user_ids)
    sql = "select from (select expand(in('Card__carded_for')) from Organization where kyck_id='#{org.kyck_id}')" +
      " where out_Card__carded_user.kyck_id in ['#{user_ids.join("','")}'] limit 30 group by (duplicate_lookup_hash, approved_on)"
    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.for_competition_and_users(competition, user_ids)
     sql = "select from (traverse in_Card__processor from #{competition._data.id}) where @class = 'Card'" +
        "where out_Card__carded_user.kyck_id in ['#{user_ids.join("','")}'] limit 30 group by (duplicate_lookup_hash, approved_on)"
    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.for_competition_and_cards(card_ids)
    sql = "select from Card where kyck_id in ['#{card_ids.join("','")}'] limit 30 group by (duplicate_lookup_hash, approved_on) "
    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.for_team_and_users(team, user_ids)
    sql ="(select expand(in('Card__carded_user')) from (select " \
      'expand(distinct(out))  from (traverse out_Team__rosters, ' \
      'in_staff_for, in_plays_for from (select from Team where kyck_id = ' \
      "'#{team.kyck_id}')) where @class IN ['staff_for', " \
      "'plays_for'])) where out_Card__carded_user.kyck_id in ['#{user_ids.join("','")}'] limit 30 group by (duplicate_lookup_hash, approved_on)"
    cmd = OrientDB::SQLCommand.new(sql)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end

  def self.cards_for_sql(sql_command)
    cmd = OrientDB::SQLCommand.new(sql_command)
    Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
  end
end

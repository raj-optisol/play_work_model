require_relative 'condition_builder'

module SanctioningRequestRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class SanctioningRequest

  def self.find_by_status(status)
    find_by_attrs(conditions: {status: status})
  end

  def self.find_all_by_status(status, sb=nil)
    sb = SanctioningBodyRepository.all.first if !sb
    sql = "select from (traverse in_target from #{sb._data.id}) where status='#{status}'"
    res = execute_sql(sql)
    res.map { |c| c.wrapper.model_wrapper }
  end


  def self.find_requests_targeting_organization(sanctioning_body, opts={})
    opts = opts.symbolize_keys

    filters = opts[:conditions] || {}

    if filters[:id]
      return [wrap(data_class.find(filters[:id]))]
    end

    namefilter = filters.delete(:name_like)
    namefilter = namefilter.downcase if namefilter

    sql = "select from (traverse in_target from #{sanctioning_body._data.id}) " \
     ' where @class="SanctioningRequest"'
    sql = sql + " and out_on_behalf_of.name.toLowerCase() like '%#{namefilter}%'" unless namefilter.blank?
    fq = ConditionBuilder::OrientGraph.sql_build(filters) unless filters.blank?
    sql = sql + " and "+fq unless fq.blank?

    opts = {limit: 25, offset: 0}.merge(opts)
    sql = sql + " order by #{opts[:order]} " if opts[:order]
    sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

    puts sql
    execute_sql(sql).map { |t| t.wrapper.model_wrapper }
  end

  def self.find_requests_on_behalf_of_organization(organization, opts)

    opts = opts.symbolize_keys
    filters = opts[:conditions] || {}
    if filters[:id]
      return [self.find(filters[:id])]
    elsif filters[:kyck_id]
      return [self.find(kyck_id:filters[:kyck_id]) ]
    end
    query = start_query_with(organization)
    query.in("on_behalf_of")
    query = ConditionBuilder::OrientGraph.build(query, filters)

    query = handle_query_options(query, opts)
    query.to_a.collect{|c| wrap c.wrapper }

  end


  def self.get_pending_request(org)
    return org.sanctioning_requests.select {|req| req.status == :pending || req.status == :pending_payment }.first
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





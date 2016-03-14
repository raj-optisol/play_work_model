module SanctionRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class Sanction

  def self.sanctions_query(sanctioning_body, filters = {}, state = nil, opts = {})
    sql = "select"
    sql = sql + " *, coalesce(in.kind, in.@class.toLowerCase()) as kind" if opts[:order] == 'kind'
    sql = sql + " from (traverse out_sanctions from #{sanctioning_body.id}) where @class='sanctions' "
    sql = sql + " and " + ConditionBuilder::OrientGraph.sql_build(filters) unless filters.blank?
    sql = sql + " let $st = (select state from $current.in.out_locations where state = '#{state.abbr}')" if state
    sql
  end

  def self.sanctions_union_query(sanctioning_body, sanction_filters = {}, s_filters = {}, sanction_types = [], state = nil)

    mainsql = "SELECT EXPAND( $result ) "
    sqlselect = 'select expand(inE("sanctions")) from '

    sqlwhere = " WHERE in_sanctions.out = #{sanctioning_body.id}"
    sqlwhere = sqlwhere + " and $st.size() > 0 " if state
    if s_filters[:name_like]
      nm = s_filters.delete(:name_like)
      sqlwhere = sqlwhere + " and name containstext '#{nm}'"
    end

    sqlwhere = sqlwhere + " and " + ConditionBuilder::OrientGraph.sql_build(s_filters) unless s_filters.blank?
    sqlwhere = sqlwhere + " and " + ConditionBuilder::OrientGraph.sql_build(sanction_filters) unless sanction_filters.blank?
    sqlwhere = sqlwhere + " let $st = (select state from $current.out_locations where state = '#{state.abbr}')" if state

    cnt = 0
    stsqlarr = []
    starr = []
    if sanction_types.count == 1
      mainsql = sqlselect + sanction_types.first + sqlwhere
    else
      sanction_types.each do |st|
        cnt += 1
        lt = "$#{cnt} = ( " + sqlselect + st + sqlwhere + ")"
        starr << "$#{cnt}"
        stsqlarr << lt
      end

      return unless starr.count > 0

      stsqlarr << "$result = UNIONALL(#{starr.join(', ')})"
      mainsql = mainsql + "LET " + stsqlarr.join(', ')
    end
    mainsql
  end

  def self.get_sanctions(sanctioning_body, options = {}, state = nil)

    filters = options[:conditions] || {}

    s_filters = filters.delete(:item) || {}
    s_filters[:migrated_id] = filters.delete(:migrated_id) if filters[:migrated_id]
    s_filters[:kyck_id] = filters.delete(:sanctioned_item_id) if filters[:sanctioned_item_id]
    s_filters[:name_like] = filters.delete(:name_like) if filters[:name_like]

    ctype = filters.delete("ctype")
    if ctype && ['Organization', 'Competition'].include?(ctype)
      cls = ctype
    end

    sanction_types = ['Organization', 'Competition']
    sanction_types = sanction_types & [cls] if cls
    sanction_filters = {}

    opts = { limit: 25, offset: 0 }.merge(options)
    order_prepend = ""
    sql = if s_filters.blank? && sanction_types.count > 1
            sanctions_query(sanctioning_body, filters, state, opts)
          else
            filters.each {|k, v| sanction_filters["in_sanctions.#{k}"] = v unless v.blank? }
            innersql = sanctions_union_query(sanctioning_body, sanction_filters, s_filters, sanction_types, state)
            if sanction_types.count > 1
              order_prepend = "in."
            end
            unless opts[:order].blank?
              sqlselect = "select"
              sqlselect = "select *, coalesce(in.kind, in.@class.toLowerCase()) as kind" if opts[:order] == 'kind'
              innersql = sqlselect + " from ( " + innersql + " )"
            end
            innersql
          end


    opts[:order] = case opts[:order]
                   when 'sanctioned_item'
                     order_prepend + 'name'
                   when 'migrated_id'
                     order_prepend + 'migrated_id'
                   else
                     opts[:order]
                   end

    sql = sql + " order by #{opts[:order]} #{opts[:order_dir]}" if opts[:order]
    sql = sql + " limit #{opts[:limit]} offset #{opts[:offset]}"

    Rails.logger.info(sql)

    cmd = OrientDB::SQLSynchQuery.new(sql).setFetchPlan("in:1")
    res = Oriented.graph.command(cmd).execute.map{|t| t.wrapper.model_wrapper}
    res
  end
end

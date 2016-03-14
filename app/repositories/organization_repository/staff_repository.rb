module OrganizationRepository
  module StaffRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Staff

    def self.create_staff(org, attrs)
      staff = Staff.build(attrs)
      staff.organization_id = org.id
      persist staff
    end

    def self.destroy_staff(org, id)
      delete_by_id(id)
    end

    def self.get_staff(org, opts={})

      if org.kind_of?(SanctioningBody) || org.kind_of?(State)
        @gp = staff_pipeline_for_sb(org, opts)
      else
        @gp = staff_pipeline_for(org, opts)
      end

      offset = opts.fetch(:offset, 0).to_i

      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 if limit > 0

      if opts[:order]
        prop = opts[:order]
        p, v = prop.split('.')
        prop = "in.#{v}" if p == 'staffed_item'
        @gp.orderby(prop, opts[:order_dir])
      else
        @gp.orderby(['out.last_name', 'out.first_name'], ['asc', 'asc'])
      end
      @gp.range(offset, limit)
      @gp.collect { |c| wrap (c.wrapper) }
    end

    def self.staff_pipeline_for_sb(sb, opts)
      staff_filters = opts[:staff_conditions] || {}
      user_filters = opts[:user_conditions] || {}

      sbid = sb._data.id
      start_query = "select expand(inE('staff_for')) from (traverse out_SanctioningBody__states from ##{sbid})"
      gp = start_query_with(Oriented.graph.command(OrientDB::SQLCommand.new(start_query)).execute)
      gp.as('staff')
      gp = ConditionBuilder::OrientGraph.build(gp, staff_filters)

      unless user_filters.empty?
        gp.outV
        gp = ConditionBuilder::OrientGraph.build(gp, user_filters)
        gp.back('staff')
      end

      gp
    end

    def self.staff_pipeline_for(org, opts={})
      staff_filters = opts[:staff_conditions] || {}
      user_filters = opts[:user_conditions] || {}
      team_filters = opts[:team_conditions] || {}

      @gp = start_query_with(org._data)

      sql = "select expand(inE('staff_for')) from (traverse out_Organization__teams from #{org._data.id} )"

      # puts sql
      @gp = KyckPipeline.new(Oriented.graph)
      @gp.KE('sql', sql)
      @gp.as('staff')

      unless team_filters.empty?
        @gp.inV.filter{ |staffable| staffable["@class"] == 'Team' }
        @gp = ConditionBuilder::OrientGraph.build(@gp, team_filters)
        @gp.back('staff')
      end

      @gp = ConditionBuilder::OrientGraph.build(@gp, staff_filters)

      unless user_filters.empty?
        @gp.outV
        @gp = ConditionBuilder::OrientGraph.build(@gp, user_filters)
        @gp.back('staff')
      end

      @gp
    end

    def self.get_staff_by_title_and_staffable(title, staffable)
      return [] if title.blank?
      return [] if staffable.blank?
      staffable = staffable._data.id

      sql = "select from (traverse in_staff_for from #{staffable})"
      sql += " where @class='staff_for' and title='#{title}'"

      execute_sql(sql).map { |c| wrap c.wrapper }
    end

    def self.get_staff_count_for_obj(obj)
      gp = self.staff_pipeline_for(obj)
      gp.outV.dedup.count
    rescue => e
      puts e.inspect
      0
    end

    def self.get_staff_summary_for_obj(obj, opts={}, current=true)
      grouped_res = {}
      gp = self.staff_pipeline_for(obj, opts)

      key_function = KyckPipeFunction.new
      key_function.send(:define_singleton_method, :compute) { |it|
        it['role']
      }

      gp.group_count(grouped_res, key_function)
      gp.iterate

      grouped_res
    rescue => e
      puts e.inspect
      {}
    end

    def self.for_organization_last_name_birthdate(org, last_name, birthdate)
       sql = "select from (select expand(inE('staff_for'))" +
             " from (traverse out_Organization__teams, out_Team__rosters from #{org._data.id}))" +
             " where out.last_name.toLowerCase() like '%#{last_name.downcase.sql_escape}%'" +
             " and out.birthdate = '#{birthdate}'"
       cmd  = OrientDB::SQLCommand.new(sql)
       Oriented.graph.command(cmd).execute.map { |c| wrap c.wrapper }
    end
  end
end

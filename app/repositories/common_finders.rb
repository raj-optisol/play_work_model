module CommonFinders
  # def find_by_id(id)
  #   where(id: id)
  # end

  module ActiveRecord
    #
    # search the repository, return the results
    # params:
    #  condtions: A hash of condtions (duh). Examples:
    #   {name: 'Bob'} => where name='Bob'
    #   {name_like: 'Bob'} => where name like '%Bob%'
    #
    #  options:  limit, and orderying
    #   {order: "id desc", limit: 5, offset: 20}
    #
    #  includes: Array of classes to include
    def find_by_attrs(conditions={}, options = {}, includes=[])
      conditions ||= {}
      options ||= {}

      # Sometimes, filter is a string
      filters = (conditions.is_a?(Hash) ? conditions : JSON.parse(conditions) )

      conditions = ConditionBuilder::SQL.build(filters)

      opts = {order: 'id desc', limit: 25, offset: 0}.merge(options)
      Rails.logger.info "*** #{opts.inspect}"
      if opts[:order] && opts[:order_dir]
        opts[:order] += " #{opts[:order_dir]}"
      end
      query = data_class.klass.where(conditions).order(
        opts[:order]
      ).limit(opts[:limit])

      query = query.limit(opts[:limit])   if opts[:limit] && opts[:limit] >= 0
      query = query.offset(opts[:offset])
      query = query.includes(*includes) unless includes.empty?

      query.map do |data|
        wrap(data)
      end || []
    end

  end

  module OrientGraph

    def find_by_kyck_id(kyck_id)
      return self.find(kyck_id:kyck_id)
    end

    def find_by_attrs_sql(opts={})
      sql = "select from #{Oriented::Registry.odb_class_for(data_class.name.to_s)} "

      filter_str = build_sql_filters(opts[:conditions]) if opts[:conditions]
      sql = "#{sql} where #{ filter_str }" unless filter_str.blank?
      sql = "#{sql} #{ build_sql_options(opts) }"

      results = execute_sql(sql)

      results.map {|c| wrap c.wrapper}
    end

    def find_by_attrs(opts={})
      opts = opts.symbolize_keys
      filters = opts[:conditions] || {}
      if filters[:id]
        return [self.find(filters[:id])]
      elsif filters[:kyck_id]
        return [self.find(kyck_id:filters[:kyck_id]) ]
      end

      g = Oriented.graph
      g.autoStartTx=false
      g.commit

      query = g.query().labels(Oriented::Registry.odb_class_for(data_class.name.to_s))
      query = ConditionBuilder::OrientGraph.build(query, filters)

      if opts[:order]
        if opts[:order_dir]
          query.order(opts[:order], opts[:order_dir])
        else
          query.order(opts[:order])
        end
      end

      offset = opts.fetch(:offset, 0).to_i
      limit = opts.fetch(:limit, 30).to_i

      query.skip(offset)
      query.limit(limit)
      res = query.vertices.collect{|c| wrap c.wrapper }
      g.autoStartTx=true
      g.commit
      res
    end

    def get_items(obj, relType, opts={}, user=nil, permissions=[])

      obj = obj._data if obj.respond_to?(:_data)

      offset = opts.fetch(:offset, 0).to_i
      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 unless limit == 0

      filters = opts[:conditions] || {}
      seas = []

      begin

        if user && permissions.length > 0
          seas = get_objects_from_permissions(user, obj, relType, permissions)
        end

        @gp = start_query_with(obj)
        @gp.out(relType)
        @gp = ConditionBuilder::OrientGraph.build(@gp, filters)
        @gp.retain(seas) unless seas.empty?

        if opts[:order]
          @gp.orderby(opts[:order], opts[:order_dir])
        end
        @gp.range(offset, limit)
        @gp.collect { |v| wrap v.wrapper }
      end

    rescue => ex
      Raven.capture_exception(ex)
      puts "*** ERROR get_items: #{ex.message}"
    end

    def get_objects_from_permissions(user, obj, relType, permissions)
      @gp = KyckPipeline.new(Oriented.graph)
      @gp1 = KyckPipeline.new(Oriented.graph)
      @gp2 = KyckPipeline.new(Oriented.graph)
      @gp3 = KyckPipeline.new(Oriented.graph)
      while_pf, emit_pf = self.while_and_emit_pipe_functions(5)
      seas = []

      @gp = start_query_with(user)
      @gp.outE('staff_for').filter{|it| it['permission_sets'].containsAll(permissions) }.as('staff').inV
      @gp.or(@gp1.filter{|it|
        if it.record.rid == obj.id.to_s
          @gp4 = KyckPipeline.new(Oriented.graph)
          @gp4.start(it).out(relType).fill(seas)
          true
        elsif it.get_edges(obj.__java_obj, OrientDB::BLUEPRINTS::Direction::IN).to_a.count > 0
          seas << it;
          true
        else
          false
        end
      }, @gp3.out.loop(1, while_pf, emit_pf).filter{|it|
        if it.id.toString() == obj.id.to_s
          @gp4 = KyckPipeline.new(Oriented.graph)
          @gp4.start(it).out(relType).fill(seas)
          true
        else
          false
        end
      }).iterate
      seas
    end

    def start_query_with(obj)
      raise ArgumentError.new('** Cannot start traverse with nil object') unless obj
      gp = KyckPipeline.new(Oriented.graph)
      obj = obj._data if obj.respond_to?(:_data)
      obj = obj.__java_obj if obj.respond_to?(:__java_obj)
      obj.load if obj && obj.respond_to?(:identity) && obj.identity.persistent?
      gp.start(obj)
      gp
    end

    def handle_query_options(query, opts)
      if opts[:order]
        if opts[:order_dir]
          query.orderby(opts[:order], opts[:order_dir])
        else
          query.orderby(opts[:order])
        end
      end

      offset = opts.fetch(:offset, 0).to_i
      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 unless limit == 0

      query.range(offset, limit)
      query
    end

    def while_and_emit_pipe_functions(number_of_loops = 3)
      while_pf = KyckPipeFunction.new
      while_pf.send(:define_singleton_method, :compute) do |arg| arg.loops < number_of_loops end
      emit_pf = KyckPipeFunction.new
      emit_pf.send(:define_singleton_method, :compute) do |arg| true; end
      [while_pf, emit_pf]
    end

    def define_pipe_function &block
      func = KyckPipeFunction.new
      func.send(:define_singleton_method, :compute) { |it|
        yield(it)
      }
    end

    def count
      Oriented.graph.raw_graph.get_class(Oriented::Registry.odb_class_for(data_class)).count()
    end

    def build_sql_filters(filters, prepend_label = nil)
      filter_sql = '1=1'
      %w(last_name_like first_name_like name_like).each do |k|
        nm = filters.delete(k)
        next unless nm
        filter_sql += ' and '
        filter_sql +=  "#{prepend_label}." if prepend_label && !prepend_label.blank?
        filter_sql +=
          "#{k.gsub('_like','')}.toLowerCase() like \"%#{nm.downcase.sql_escape}%\""
      end

      # Handle date fields
      new_filters = filters.map do |k, v|
        key = prepend_label ? "#{prepend_label}." : ''
        { "#{key}#{k}" => v }
      end.reduce({}, :merge)
      s = ConditionBuilder::OrientGraph.sql_build(new_filters)
      filter_sql = "#{filter_sql} and #{s}" unless s.blank?
      filter_sql
    end

    def build_sql_options(opts)
      sql = ''
      opts = { limit: 25, offset: 0 }.merge(opts)
      sql += " order by #{opts[:order]} " \
        "#{opts[:order_dir] || 'asc'} " if opts[:order]
      sql + " limit #{opts[:limit]} offset #{opts[:offset]}"
    end

    def execute_sql(sql)
      Rails.logger.info("Executing SYNCH Query: #{sql}")
      cmd = OrientDB::SQLSynchQuery.new(sql)
      Oriented.graph.command(cmd).execute
    end

    # Finder methods for Vertex classes
    module Vertex
    end

    # Finder methods for Edge classes
    module Edge
      def find_by_kyck_id(kyck_id)
        u = Oriented.graph.query
          .labels(Oriented::Registry.odb_class_for(data_class))
          .has('kyck_id', kyck_id).vertices.to_a.first

        return wrap u.wrapper if u
      end
    end
  end
end

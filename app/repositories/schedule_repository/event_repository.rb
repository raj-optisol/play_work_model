module ScheduleRepository
  module EventRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Event

    def self.get_events_for_obj(obj, opts={})
      opts = opts.symbolize_keys
      offset = opts.fetch(:offset, 0).to_i
      limit = opts.fetch(:limit, 30).to_i+offset
      limit -= 1 unless limit == 0

      filters = opts[:conditions] || {}

      pf = KyckPipeFunction.new
      pf.send(:define_singleton_method, :compute) do |arg| arg.loops < limit end
      pf2 = KyckPipeFunction.new
      pf2.send(:define_singleton_method, :compute) do |arg| return false unless arg.loops > offset && arg.loops <= limit; return true; end


      scheduleLoops = KyckPipeFunction.new
      scheduleLoops.send(:define_singleton_method, :compute) do |arg| arg.loops < 4 end
      emitLoops = KyckPipeFunction.new
      emitLoops.send(:define_singleton_method, :compute) do |arg| return true; end

      @gp = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)        
      s = @gp.start(obj._data.__java_obj).outE.filter{|e|  ['Team__schedules', 'Schedule__schedules'].include?(e.label) }.inV.loop(3, scheduleLoops, emitLoops).out("Schedule__events")
      @gp = ConditionBuilder::OrientGraph.build(@gp, filters)          

      if opts[:order]
        order_dir = (opts[:order_dir] && opts[:order_dir].downcase == 'asc' ? 1 : -1)
        prop = opts[:order]
        @gp.order{|it| if !it.a[prop].kind_of?(Fixnum) && !it.a[prop].kind_of?(Java::JavaUtil::Date); pr1 = it.a[prop].downcase; pr2 = it.b[prop].downcase; else pr1 = it.a[prop]; pr2 = it.b[prop]; end; (order_dir*(pr1 <=> pr2)).to_java(:int) }
      end        
      @gp.range(offset, limit)


      m = @gp.collect{|m| m.wrapper }
    end

    def self.update_reoccurring_event(evt, attrs)
      eventrule = evt.rule;
      newrule = attrs.delete("rule")
      if !newrule          
        sd = attrs["start_date"]   
        ed = attrs["end_date"]
        td = ed-sd

        ets = get_items(eventrule, "Rule__events", {conditions:{start_date_gt:evt.start_date}})         
        ets.each{|e|
          e.start_date = Time.at(e.start_date).change({:hour => Time.at(sd).hour, :min => Time.at(sd).min}).to_i
          e.end_date= e.start_date+td.seconds
          persist(e)
        }
      else
      end
    end
  end
end

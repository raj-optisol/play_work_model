require 'benchmark'

class Schedule
  include Edr::Model
  include BaseModel::Model

  # def_delegators :_data, :add_roster, :remove_roster  

  wrap_associations :schedules, :rules, :events, :team

  # def create_division(attrs)
  #   wrap association(:divisions).create(attrs)
  # end
  
  def create_rule(attrs)

    if attrs.is_a?(Array)
      attrs.each{|attr|
        attr["days_of_week"] = attr["days_of_week"].inject([]) {|h, (key,value)| h << value.to_i } if attr["days_of_week"].is_a?(Hash)  
        ["start_date", "end_date"].each{|d| attr[d] = DateTime.strptime(attr[d].to_s, "%m/%d/%Y").to_i if attr[d] && !attr[d].is_a?(Time) }             
        attr["time_ranges"] = [attr.delete("start_time")+".."+attr.delete("end_time")] if attr.has_key?("start_time") && attr.has_key?("end_time")
        wrap association(:rules).create(attr)
      }
    else
        attrs["days_of_week"] = attrs["days_of_week"].inject([]) {|h, (key,value)| h << value.to_i } if attrs["days_of_week"].is_a?(Hash)
      ["start_date", "end_date"].each{|d| attrs[d] = DateTime.strptime(attrs[d].to_s, "%m/%d/%Y").to_i if attrs[d] && !attrs[d].is_a?(Time) }     
      attrs["time_ranges"] = [attrs.delete("start_time")+".."+attrs.delete("end_time")] if attrs.has_key?("start_time") && attrs.has_key?("end_time")

      wrap association(:rules).create(attrs)      
    end
    # end
  end
  
  def create_event(attrs)
    newattrs = {}
    attrs.stringify_keys!
    %w(name memo start_date end_date).each do |attr|
      newattrs[attr] = attrs.fetch(attr) if attrs.has_key?(attr)
    end    
    wrap association(:events).create(newattrs)    
  end
  
  def create_schedule(attrs)

    utc_offset = (attrs[:timezone_offset] ? attrs[:timezone_offset].to_i*(60) : 0)
    Chronic.time_class = Time.zone        
    [:start_date, :end_date].each{|d| attrs[d] = (Chronic.parse(attrs[d].to_s)+utc_offset).to_i if attrs[d] && !attrs[d].is_a?(Time) }
    
    # [:start_date, :end_date].each{|d| attrs[d] = DateTime.strptime(attrs[d].to_s, "%m/%d/%Y") if attrs[d] && !attrs[d].is_a?(Time) }     
    attrs.stringify_keys!

    newattrs = {}
    %w(name start_date end_date).each do |attr|
      newattrs[attr] = attrs.fetch(attr) if attrs.has_key?(attr)
    end

    ss = wrap association(:schedules).create(newattrs)
            
    rs = attrs.delete("rules")
    
    rs = rs.inject([]) {|h, (key,value)| h << value} if rs.is_a?(Hash) && rs.has_key?("0")
    ss.create_rule(rs)            
    ss.create_events_from_rules
    ss
    
  end
  
  # def add_schedule (schedule)
  #   _data.schedules << schedule._data   
  # end
  
  # 18.110000   7.230000  25.340000 ( 31.491000) all
  # 0.760000   0.020000   0.780000 (  0.465000) no event
  # 17.120000   7.010000  24.130000 ( 29.478000) no validation
  # 16.420000   6.920000  23.340000 ( 29.330000) with no end_date
  # 14.870000   6.930000  21.800000 ( 27.488000)  with no dates
  # 1.360000   0.030000   1.390000 (  0.821000)  not using wrap association
  # t2.schedules.first.schedules.each{|s| s.events.each{|e| e._data.delete }; s._data.delete }
  
  def create_events_from_rules

    single_exceptions = rules.select {|r| r.kind == :unavailable && Time.at(r.start_date).to_date == Time.at(r.end_date).to_date }.inject({}) { |result, r| result[Time.at(r.start_date).to_date.to_s] = nil; result }
    single_available = rules.select {|r| r.kind == :available && Time.at(r.start_date).to_date == Time.at(r.end_date).to_date }.inject({}) { |result, r| result[Time.at(r.start_date).to_date.to_s] = (r.time_ranges ? r.time_ranges : [Time.at(r.start_date).strftime("%H%M")+".."+Time.at(r.end_date).strftime("%H%M")]); result }
    
    exceptions = rules.select {|r| r.kind == :unavailable && Time.at(r.start_date).to_date != Time.at(r.end_date).to_date}.inject({}) { |result, r| (Time.at(r.start_date).to_datetime..Time.at(r.end_date).to_datetime).to_a.select {|k| r.days_of_week.include?(k.wday)}.inject(result) { |result2, element| result2[element.to_date.to_s] = r.time_ranges; result }}

    avail = rules.select {|r| r.kind == :available && Time.at(r.start_date).to_date != Time.at(r.end_date).to_date}.inject({}) { |result, r| (Time.at(r.start_date).to_datetime..Time.at(r.end_date).to_datetime).to_a.select {|k| r.days_of_week.include?(k.wday)}.inject(result) { |result2, element| result2[element.to_date.to_s] = r.time_ranges; result }}    

    av = avail.select {|k,v| !exceptions.has_key?(k) }
    allavailable = Hash[av.merge(single_available||{}).select{|k,v| !single_exceptions.has_key?(k) }]

    allavailable.keys.sort.each{|k| 
      v = allavailable[k]
      eventattrs = {
        name:self.name
      }
      starttime = endtime = nil
      v.each {|t| 
        st, et = t.split("..")
        # puts "startdate = #{DateTime.strptime(k+":"+st, "%Y-%m-%d:%H%M")}  and enddate = #{DateTime.strptime(k+":"+et, "%Y-%m-%d:%H%M")}"
        eventattrs["start_date"] = DateTime.strptime(k+":"+st, "%Y-%m-%d:%H%M").to_i
        eventattrs["end_date"] = DateTime.strptime(k+":"+et, "%Y-%m-%d:%H%M").to_i
      }
      self._data.events << Event.build(eventattrs)._data
      # create_event(eventattrs)    
    }
  # }
    
  end
  
  def create_reoccurring_event(attrs, location=nil)

    attrs.stringify_keys!
    attrs = KyckRegistrar::DateUtility::unix_timestamp_dates(["start_date", "end_date"], attrs, attrs.delete("timezone_offset"))    
    # utc_offset = (attrs[:timezone_offset] ? attrs[:timezone_offset].to_i*(60) : 0)
    # Chronic.time_class = Time.zone        
    # [:start_date, :end_date].each{|d| attrs[d] = Chronic.parse(attrs[d].to_s)+utc_offset if attrs[d] && !attrs[d].is_a?(Time) }
    # puts "#{Time.at(attrs["start_date"]).utc} and end date = #{Time.at(attrs["end_date"]).utc}"
    attrs["time_ranges"] = [Time.at(attrs["start_date"]).utc.strftime("%H%M")+".."+Time.at(attrs["end_date"]).utc.strftime("%H%M")]
    attrs["days_of_week"] = attrs["days_of_week"].inject([]) {|h, (key,value)| h << value.to_i } if attrs["days_of_week"].is_a?(Hash)
        
    newattrs = {}
    %w(name memo start_date end_date days_of_week time_ranges kind).each do |attr|
      newattrs[attr] = attrs.fetch(attr) if attrs.has_key?(attr)
    end


    ru = Rule.build(newattrs)
		ScheduleRepository.persist (ru)
    self._data.rules << ru._data          
    self.create_events_from_rule(ru, location)
    self
    
  end
  
    def create_events_from_rule(rule, location=nil)
      allavailable = (Time.at(rule.start_date).utc.to_datetime..Time.at(rule.end_date).utc.to_datetime).to_a.select {|k| rule.days_of_week.include?(k.wday)}.inject({}) { |result, element| result[element.to_date.to_s] = rule.time_ranges; result }    

      allavailable.each{|k,v| 
        eventattrs = {
          name:(rule.name || self.name),
          memo: (rule.attributes['memo'] || '')
        }
        starttime = endtime = nil
        v.each {|t| 
          st, et = t.split("..")
          eventattrs["start_date"] = DateTime.strptime(k+":"+st, "%Y-%m-%d:%H%M").to_i        

          if et.to_i < st.to_i   
            sth = st[0..1]
            stm = st[2..3]
            sdh = 24-sth.to_i
            sdm = 60-stm.to_i;
            sdh = sdh-1 if sdm > 0
            
            eth = et[0..1]
            etm = et[2..3]
            edh = sdh+eth.to_i
            edm = sdm+etm.to_i;

            secs = (edh*3600)+(edm*60)

            eventattrs["end_date"] = eventattrs["start_date"]+secs.seconds

          else
            eventattrs["end_date"] = DateTime.strptime(k+":"+et, "%Y-%m-%d:%H%M").to_i  
          end
        }
        evt = Event.build(eventattrs)
				evt.add_location(location) if location
        ScheduleRepository::EventRepository.persist evt
        rule._data.events << evt._data
        self._data.events << evt._data
        
      }

    end

end

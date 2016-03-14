require 'spec_helper'
require 'date'

describe Schedule do

  subject{
    s = Schedule.build(name: "Master One", start_date:(2.months.from_now), end_date:5.months.from_now)
    ScheduleRepository.persist(s)
  }
  let(:user) {regular_user}

  it "has a name" do
    subject.name = "Practice"
    subject.name.should == "Practice"
    
  end
  
  it "has a start_date" do
    dt = 2.days.from_now.to_i
    subject.start_date = dt
    subject.start_date.should be_a(Fixnum)
  end
  
  it "has an end_date" do
    dt = 2.months.from_now.to_i
    subject.end_date = dt
    subject.end_date.should be_a(Fixnum)
  end
  
  describe "rules" do
    
    it "are empty be default" do
      subject.rules.should == [] 
    end
  
    it "can be added to a schedule" do
            
      expect {
        subject.create_rule(name:"Exception Rule", start_date:subject.start_date+15.days, end_date:subject.start_date+20.days, days_of_week:[1,3], kind:"unavailable")
      }.to change{subject.rules.count}.by(1)
    end
  end
  
    describe "events" do
    
      it "are empty be default" do
        subject.events.should == [] 
      end
    
      describe "#create_events_from_rules" do 
        context "when only single availability rule" do
            let!(:rule) {
                r = subject.create_rule(name:"Rule One", start_date:subject.start_date+7.days, end_date:subject.start_date+7.days, time_ranges:["0500..0800"])            
                ScheduleRepository.persist(subject)              
                r
            }
            it "only adds one" do
              assert_difference lambda {subject.events.count} do
                subject.create_events_from_rules
                ScheduleRepository.persist(subject)            
              end
            end
          
            it "event start datetime should equal rule startime and time range " do
                subject.create_events_from_rules
                ScheduleRepository.persist(subject)       
                subject.events.first.start_date.should == DateTime.strptime(Time.at(rule.start_date).to_date.to_s+":0500", "%Y-%m-%d:%H%M").to_i
                subject.events.first.end_date.should == DateTime.strptime(Time.at(rule.start_date).to_date.to_s+":0800", "%Y-%m-%d:%H%M").to_i
            end
          end
      
      context "when 2 single availability rule" do
        let!(:rule1) {
            r = subject.create_rule(name:"Rule One", start_date:subject.start_date+7.days, end_date:subject.start_date+7.days, time_ranges:["0500..0800"])            
            ScheduleRepository.persist(subject)              
            r
        }
        let!(:rule2) {
            r = subject.create_rule(name:"Rule Two", start_date:subject.start_date+10.days, end_date:subject.start_date+10.days, time_ranges:["1530..1700"])            
            ScheduleRepository.persist(subject)              
            r
        }          
        it "only adds 2" do
          expect {
            subject.create_events_from_rules
            ScheduleRepository.persist(subject)            
          }.to change{subject.events.count}.by(2)
        end
        
        it "event start datetime should equal rule startime and time range " do
            subject.create_events_from_rules
            ScheduleRepository.persist(subject)         
            start_dates = subject.events.map(&:start_date)
            end_dates = subject.events.map(&:end_date)

            start_dates.should include  DateTime.strptime(Time.at(rule1.start_date).to_date.to_s+":0500", "%Y-%m-%d:%H%M").to_i
          end_dates.should include  DateTime.strptime(Time.at(rule1.end_date).to_date.to_s+":0800", "%Y-%m-%d:%H%M").to_i
            
            start_dates.should include DateTime.strptime(Time.at(rule2.start_date).to_date.to_s+":1530", "%Y-%m-%d:%H%M").to_i
            end_dates.should include DateTime.strptime(Time.at(rule2.end_date).to_date.to_s+":1700", "%Y-%m-%d:%H%M").to_i
            
        end
      end
        
      context "when 1 reoccurring availability rule" do
        context "with only single day of week" do
          let!(:rule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+13.days, days_of_week:[3], time_ranges:["0500..0800"])            
              ScheduleRepository.persist(subject)              
              r
          }     
          it "only adds 2" do
            expect {
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)            
            }.to change{subject.events.count}.by(2)
          end
        
          it "event start datetime should equal rule startime and time range " do
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)    
              Time.at(subject.events.first.start_date).wday.should == 3
              Time.at(subject.events.last.start_date).wday.should == 3              
          end
        end
        context "with 2 days of the week" do
          let!(:rule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[1,3], time_ranges:["0500..0800"])            
              ScheduleRepository.persist(subject)              
              r
          }        
          it "only adds 2" do
            expect {
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)            
            }.to change{subject.events.count}.by(2)
          end
        
          it "event days should be only the days set by the rule " do
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)    
              rule.days_of_week.should include(*subject.events.collect{|e| Time.at(e.start_date).wday})
          end
        end          
      end
      
      context "when 1 reoccurring availability rule and 1 single availability rule" do
          let!(:singlerule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.end_date-1.day, end_date:subject.end_date-1.day, time_ranges:["1500..1630"])            
              ScheduleRepository.persist(subject)              
              r
          }
          let!(:rule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[2,3], time_ranges:["0500..0800"])            
              ScheduleRepository.persist(subject)              
              r
          }   
          it "adds 3 events" do
            expect {
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)            
            }.to change{subject.events.count}.by(3)
          end
        
          it "event start datetime should equal rule startime and time range " do
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)    
              rule.days_of_week.should include(*subject.events.first(2).collect{|e| Time.at(e.start_date).wday})
              Time.at(subject.events.last.start_date).wday.should == (Time.at(subject.end_date)-1.day).wday
          end      
      end
      
      context "when 1 reoccurring availability rule and 1 single exception rule" do
          let!(:singlerule) {
              sd = Time.at(subject.start_date)
              wday = sd.wday
              start_date = case wday
              when 0
                sd+2.days
              when 1 
                sd+1.day
              when 2
                sd
              else
                sd+(6-wday+3).days
              end            
              r = subject.create_rule(name:"Exception Rule", start_date:start_date, end_date:start_date, kind:"unavailable")
              ScheduleRepository.persist(subject)              
              r
          }
          let!(:rule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[2,3], time_ranges:["0500..0800"])            
              ScheduleRepository.persist(subject)              
              r
          }   
          it "add only 1 event" do
            expect {
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)            
            }.to change{subject.events.count}.by(1)
          end
        
          it "event start date should not equal exception rule startime " do
              subject.create_events_from_rules
              ScheduleRepository.persist(subject)    
              Time.at(subject.events.first.start_date).to_date.to_s.should_not == Time.at(singlerule.start_date).to_date.to_s
          end      
      end
         
      context "when 1 reoccurring availability rule and 1 reoccurring exception rule" do
          let!(:singlerule) {
              r = subject.create_rule(name:"Exception Rule", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[2], kind:"unavailable")
              ScheduleRepository.persist(subject)              
              r
          }
          let!(:rule) {
              r = subject.create_rule(name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[1,2,3], time_ranges:["0500..0800"])
              ScheduleRepository.persist(subject)              
              r
          }   
          
          it "add 2 event" do
            subject.create_events_from_rules
            ScheduleRepository.persist(subject)              
            subject.events.count.should == 2
          end          
      end                        
    end  ### END create_events_from_rules
  
  end  ### END DESCRIBE EVENTS      

  describe "schedules" do     
    
    it "are empty be default" do
      subject.schedules.should == [] 
    end
     
    # describe "#create_reoccurring_event" do         
    #   it "event start datetime should equal rule startime and time range " do
    #       attrs = {name: "Practice One", start_date:(2.months.from_now+3.days), end_date:5.months.from_now-10.days, rules:[
    #         {name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[1,2,3], time_ranges:["0500..0800"]},
    #         {name:"Exception Rule", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[2], kind:"unavailable"}
    #         ]}     
    #       # attrs =  {"name"=>"practice", "kind"=>"reoccurring", "start_date"=>Chronic.parse("july 12th"), "end_date"=>Chronic.parse("september 12th"), "rules"=>{"0"=>{"start_date"=>"07/12/2013", "end_date"=>"07/31/2013", "days_of_week"=>{"1"=>"1", "3"=>"3"}, "start_time"=>"0800", "end_time"=>"0900"}, "1"=>{"start_date"=>"08/02/2013", "end_date"=>"09/12/2013", "days_of_week"=>{"2"=>"2", "4"=>"4"}, "start_time"=>"1630", "end_time"=>"1800"}}}
    #       ss = subject.create_reoccurring_event(attrs)
    #       ScheduleRepository.persist(ss)
    #       subject.schedules.count.should == 1          
    #       subject.schedules.first.rules.count.should == 2          
    #       # subject.schedules.first.events.to_a.each{|e| puts e.start_date }
    #       subject.schedules.first.events.count.should == 2
    #   end  
    # end  ### END create_reoccurring_event
    
    describe "#create_reoccurring_event2" do         
      it "event start datetime should equal rule startime and time range " do
          attrs = {name: "Practice One", start_date:(2.months.from_now+7.hours), end_date:(2.months.from_now+6.days+8.hours), days_of_week:[1,2,3]}
            #  rules:[
            # {name:"Rule One", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[1,2,3], time_ranges:["0500..0800"]},
            # {name:"Exception Rule", start_date:subject.start_date, end_date:subject.start_date+6.days, days_of_week:[2], kind:"unavailable"}
            # ]}     
          # attrs =  {"name"=>"practice", "kind"=>"reoccurring", "start_date"=>Chronic.parse("july 12th"), "end_date"=>Chronic.parse("september 12th"), "rules"=>{"0"=>{"start_date"=>"07/12/2013", "end_date"=>"07/31/2013", "days_of_week"=>{"1"=>"1", "3"=>"3"}, "start_time"=>"0800", "end_time"=>"0900"}, "1"=>{"start_date"=>"08/02/2013", "end_date"=>"09/12/2013", "days_of_week"=>{"2"=>"2", "4"=>"4"}, "start_time"=>"1630", "end_time"=>"1800"}}}

          ss = subject.create_reoccurring_event(attrs)
          ScheduleRepository.persist(ss)
          subject.rules.count.should == 1
          subject.events.count.should == 3          
          subject.events.first.name.should == subject.rules.first.name
          subject.events.first.rule.id.should == subject.rules.first.id          
          attrs["days_of_week"].should include(*subject.events.first(3).collect{|e| Time.at(e.start_date).utc.wday})             

      end  
    end  ### END create_reoccurring_event
    
  end  ### END DESCRIBE SCHEDULES

end

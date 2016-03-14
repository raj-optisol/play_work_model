module KyckRegistrar
  module Actions
    describe GetEvents do


      it "requires a requestor" do
        expect{described_class.new}.to raise_error ArgumentError
      end
      
      it "takes an object" do
        expect{described_class.new(User.new)}.to raise_error ArgumentError
      end


      describe "#execute" do
        describe "when the requestor has the required permisson" do
          before(:each) do
            @requestor = regular_user            
            
            @team = Team.build(name: 'New Team')          
            OrganizationRepository::TeamRepository.persist @team
            
            sdate = DateTime.now
            edate = 5.months.from_now
            @schedule = @team.create_schedule(name: "Master One", start_date:(sdate), end_date:edate, kind:"master")
            OrganizationRepository::TeamRepository.persist @team
            
            @event = @schedule.create_event({name:"onetimeevent", memo:"memo", start_date:Chronic.parse((sdate+3.days).to_s), end_date:Chronic.parse((sdate+3.days+2.hours).to_s)})            
            ScheduleRepository.persist @schedule


          end

          it "returns the events for the object" do
            action = described_class.new(@requestor, @team)            
            evts = action.execute()
            evts.count.should == 1
            evts.first.id.should == @event.id
          end
          
          it "returns all events when schedule contains reoccurring events " do
            sdate = DateTime.now
            edate = DateTime.now+6.days+2.hours
            # attrs = {name: "Practice One", kind:"reoccurring", start_date:Chronic.parse(sdate.to_s), end_date:Chronic.parse(edate.to_s), rules:[{name:"Rule One", start_date:sdate, end_date:sdate+6.days, days_of_week:[1,2,3], time_ranges:["0500..0800"]}, {name:"Exception Rule", start_date:sdate, end_date:sdate+6.days, days_of_week:[2], kind:"unavailable"}]}
            attrs = {name: "Practice One", memo:"memo", start_date:sdate, end_date:edate, days_of_week:[1,2,3]}
            create_reoccurring_event_for_schedule(@schedule, attrs)            


            action = described_class.new(@requestor, @team)            
            evts = action.execute()
            evts.count.should == (@schedule.events.count)            
            
          end
        end
      end

    end
  end
end

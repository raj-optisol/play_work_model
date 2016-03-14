module KyckRegistrar
  module Actions
    describe CreateEvent do
      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a schedule" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        let(:requestor) {regular_user}
        let(:team) {create_team}
        let(:args) {
          {name:"practice", memo:"memo", start_date:Chronic.parse(DateTime.now.to_s), end_date:Chronic.parse((DateTime.now+2.hours).to_s), address1: '123 elm st', address2: '.', city: 'clt', state: 'nc', zipcode: '28203', country: 'usa', latitude: '0', longitude: '0'}.with_indifferent_access
        }

        let(:reoccurring_args) {
          sdate = DateTime.now
          edate = DateTime.now+6.days+2.hours
          # {name: "Practice One", kind:"reoccurring", start_date:Chronic.parse(sdate.to_s), end_date:Chronic.parse(edate.to_s), rules:[{name:"Rule One", start_date:sdate, end_date:sdate+6.days, days_of_week:[1,2,3], time_ranges:["0500..0800"]}, {name:"Exception Rule", start_date:sdate, end_date:sdate+6.days, days_of_week:[2], kind:"unavailable"}]}
          {name: "Practice One", memo:"memo", kind:"recurring", start_date:Chronic.parse(sdate.to_s), end_date:Chronic.parse(edate.to_s), days_of_week:[1,2,3], address1: '123 elm st', city: 'clt', state: 'nc', zipcode: '28203'}.with_indifferent_access
        }

        context "user has permission" do

          before(:each) do
            add_user_to_org(requestor, team, {permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
          end

          it "should create a new event on master schedule" do
            result = described_class.new(requestor, team).execute(args)
            team.schedules.count.should == 1
            team.schedules.first.events.count.should == 1
          end

          it "creates a new event with dates" do
            result = described_class.new(requestor, team).execute(args)
            team.schedules.count.should == 1
            team.schedules.first.events.first.start_date.should == args[:start_date]
            team.schedules.first.events.first.end_date.should == args[:end_date]
          end

          it "should create a new reoccuring event on master schedule" do
            result = described_class.new(requestor, team).execute(reoccurring_args)
            team.schedules.count.should == 1
            team.schedules.first.events.count.should == 3
          end
        end

        context "user does not have permission" do
          it "should raise permission error" do
            expect { described_class.new(requestor, team).execute(args) }.to raise_error PermissionsError              
          end
        end

      end
    end
  end
end

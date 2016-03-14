require 'spec_helper'

module KyckRegistrar
  module Actions
    describe DeleteEvent do


      describe "#new" do
        it "should take a requestor" do
          expect{described_class.new}.to raise_error ArgumentError 
        end
        
        it "should take an event" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError 
        end
        
        it "should take a event" do
          expect{described_class.new(User.new, Event.new)}.to_not raise_error ArgumentError 
        end
      end      

      describe "#execute" do

        let(:team) {
          team = create_team
        }

        let (:schedule) {
          create_schedule_for_obj(team)
        }

        let(:event) {
          evt = create_event_for_schedule(schedule) #({name:"practice", start_date:schedule.start_date+1.day+1.hour, end_date}) 
        }
        
        let(:revent) {
          evt = create_reoccurring_event_for_schedule(schedule)
        }
        

        context "when the requestor has permission to delete the event" do
          
          let(:requestor) {
            u = regular_user
            team.add_staff(u, {title:"Dood", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
            UserRepository.persist(u)
            u
          }

          it "should tell the repo to delete the event" do
            mock = double
            mock.should_receive(:delete_by_id).with(event.id)
            action = described_class.new(requestor, event)
            action.repository = mock
            action.execute()
          end
          
          
          it "should tell the repo to delete the event" do          
             action = described_class.new(requestor, revent.events.first)                 
             input = {deleteseries: "true"}   
             action.execute input             
             schedule.events.count.should == 0
          end
          
        end

        context "when the requestor does not have permission to delete the event" do
          let(:requestor) {
            regular_user
          }

          it "should raise an error" do
            action = described_class.new(requestor, event)

            expect{action.execute()}.to raise_error PermissionsError
          end

        end
      end
    end
  end
end

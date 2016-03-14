require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateEvent, broken: true do

      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes an org" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      let(:team) {
        team = create_team
      }

      let (:schedule) {
        create_schedule_for_obj(team)
      }

      context "for updating single event" do

        let(:event) {
          evt = create_event_for_schedule(schedule) #({name:"practice", start_date:schedule.start_date+1.day+1.hour, end_date})
        }

        let(:event_attributes) {
          # {name:"practice2", start_date:(DateTime.now.to_s), end_date:(DateTime.now+2.hours).to_s}
          {name:"practice2", memo:"memo", start_date:"Jul 15, 2013 4:00:00 PM", end_date:"Jul 15, 2013 6:00:00 PM", timezone_offset:240}

        }

        context "when the requestor has manage schedule rights" do

          let(:requestor) {
            user = regular_user
            team.add_staff(user, {title:"Title", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
            UserRepository.persist user
            user
          }

          it "should set the new values on the event" do
            changed_evt = described_class.new(requestor, event).execute event_attributes
            changed_evt.name.should == event_attributes["name"].to_s
            changed_evt.memo.should == event_attributes["memo"].to_s
            changed_evt.start_date.should == event_attributes["start_date"].to_i
            changed_evt.end_date.should == event_attributes["end_date"].to_i
          end

        end

        context "when the requestor does not have permission" do

          it "should raise permission error" do
            expect { changed_evt = described_class.new(regular_user, event).execute event_attributes }.to raise_error PermissionsError
          end
        end

      end


      context "for updating reoccurring event" do

        let(:revent) {
          evt = create_reoccurring_event_for_schedule(schedule) #({name:"practice", start_date:schedule.start_date+1.day+1.hour, end_date})
        }

        let(:event_attributes) {
          # {name:"practice2", start_date:(DateTime.now.to_s), end_date:(DateTime.now+2.hours).to_s}
          {name:"practice2", memo:"memo", start_date:"Jul 15, 2013 4:00:00 PM", end_date:"Jul 15, 2013 6:00:00 PM", timezone_offset:240}

        }

        context "when the requestor has manage schedule rights" do

          let(:requestor) {
            user = regular_user
            team.add_staff(user, {title:"Title", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
            UserRepository.persist user
            user
          }

          it "should set the new values on the event" do
            event = revent.events.first
            evt_attr = {name:"practice2", memo:"memo", start_date:Time.at(event.start_date)+1.hour, end_date:Time.at(event.end_date)+1.hour}
            changed_evt = described_class.new(requestor, event).execute evt_attr
            changed_evt.name.should == evt_attr["name"].to_s
            changed_evt.memo.should == evt_attr["memo"].to_s
            changed_evt.start_date.should == evt_attr["start_date"].to_i
            changed_evt.end_date.should == evt_attr["end_date"].to_i
          end

          it "should set the new values on the event and future events" do
            allevents = ScheduleRepository::EventRepository.get_items(revent, "Schedule__events", {order:"start_date", order_dir:"asc"})
            evt =  allevents[0]
            event = allevents[1]
            event2 = allevents[2]

            evt_attr = {
              name:"practice2",
              memo:"memo",
              start_date:(Time.at(evt.start_date)+ 1.day+ 1.hour).utc,
              end_date:(Time.at(evt.end_date)+1.day+1.hour).utc,
              modifyrule:"future"
            }
            evt_cl = evt_attr.clone

            changed_evt = described_class.new(requestor, evt).execute evt_cl

            schedule._data.reload
            schedule.events.each{|et|
              sd = Time.at(et.start_date).utc
              ed = Time.at(et.end_date).utc
              if et.kyck_id != evt.kyck_id
                sd.hour.should == evt_attr[:start_date].hour
                sd.min.should == evt_attr[:start_date].min
                ed.hour.should == evt_attr[:end_date].hour
                ed.min.should == evt_attr[:end_date].min
              end

              if et.kyck_id == revent.kyck_id
                changed_evt.start_date.should == evt_cl["start_date"]
              end

            }
          end

          it "should set the new values on the event and future events" do
            # allevents = ScheduleRepository::EventRepository.get_items(revent, "ScheduleData#events", {order:"start_date asc"})
            # evt =  allevents[0]
            # event = allevents[1]
            # event2 = allevents[2]
            #
            # evt_attr = {name:"practice2", start_date:event.start_date+1.day+1.hour, end_date:event.end_date+1.day+1.hour, modifyrule:"future", rule:{days_of_week:[2,5]}}
            # changed_evt = described_class.new(requestor, event).execute evt_attr
            # schedule._data.reload
            # schedule.events.each{|et|
            #   if et.kyck_id != evt.kyck_id
            #     et.start_date.hour.should == evt_attr["start_date"].hour
            #     et.start_date.min.should == evt_attr["start_date"].min
            #     et.end_date.hour.should == evt_attr["end_date"].hour
            #     et.end_date.min.should == evt_attr["end_date"].min
            #   end
            #
            #   if et.kyck_id == event.kyck_id
            #     changed_evt.start_date.to_s.should == evt_attr["start_date"].to_datetime.to_s
            #   end
            #
            # }
          end

        end

        # context "when the requestor does not have permission" do
        #
        #   it "should raise permission error" do
        #     expect { changed_evt = described_class.new(regular_user, event).execute event_attributes }.to raise_error PermissionsError
        #   end
        # end

      end




    end
  end
end


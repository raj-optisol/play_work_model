require 'factory_girl'

FactoryGirl.define do
  sequence(:schedule_name) {|n| "Schedule#{n}"}

  factory :schedule, class: ScheduleData do
    name {FactoryGirl.generate :schedule_name}
    start_date DateTime.now
    end_date DateTime.now+2.months
    kind "regular"

    
    # trait :female do
    #   gender "F" 
    # end
    # 
    # trait :with_evt do
    #   events {FactoryGirl.create(:club)}
    # end

  end
end

# FactoryGirl.define do
#   sequence(:event_name) {|n| "Schedule#{n}"}
# 
#   factory :event, class: EventData do
#     name {FactoryGirl.generate :event_name}
#     start_date DateTime.now+1.hour
#     end_date DateTime.now+2.hours
# 
#   end
# end

def create_schedule(attrs={})
  schedule = FactoryGirl.create(:schedule)
  schedule = ScheduleRepository.find(schedule.id)
end

def create_schedule_for_obj(obj, attrs={})
  schedule = FactoryGirl.build(:schedule, attrs)
  schedule = obj.create_schedule(schedule.props.slice!("id", "created_at", "updated_at"))
  schedule = ScheduleRepository.persist schedule    
end

def create_event_for_schedule(schedule, evt={}, repo = ScheduleRepository)
  dt = Time.at(schedule.start_date)
  dt.change({:hour => 14})
  evt = {name:"practice", start_date: dt, end_date:dt+1.hour}.merge(evt)
  event = schedule.create_event(evt)
  repo.persist! schedule
  event
end

def create_reoccurring_event_for_schedule(schedule, evt={}, repo = ScheduleRepository)
  dt = Time.at(schedule.start_date).utc
  dt.change({:hour => 14})
  evt = {name:"practice", start_date: dt, end_date:dt+6.days+1.hour, days_of_week:[1,3,5]}.merge(evt)
  event = schedule.create_reoccurring_event(evt)
  repo.persist schedule
  event
end

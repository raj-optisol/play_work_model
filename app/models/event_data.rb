class EventData < BaseModel::Data
  include Locatable::Data

  property :name
  property :memo
  property :start_date, type: Fixnum
  property :end_date, type: Fixnum

  has_n(:schedule).from(ScheduleData, :events)
  has_n(:locations).to(LocationData)
  has_one(:rule).from(RuleData, :events)
  # has_n(:rules).to(RuleData)  

  def start_date_cannot_be_after_end_date
    return unless start_date && end_date
    errors.add(:start_date, "Cannot be after end date") if start_date > end_date
  end
end

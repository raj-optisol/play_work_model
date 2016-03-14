class RuleData < BaseModel::Data
  property :start_date, type: Fixnum
  property :end_date, type: Fixnum
  property :name
  property :time_ranges

  property :days_of_week

  property :kind, type: :symbol, default: :available

  #symbolize :kind, in: [:available, :unavailable]

  # validates :name, presence: true
  #validate :start_time_cannot_be_after_end_time

  has_one(:schedule).from(ScheduleData, :rules)
  has_n(:events).to(EventData)

  def start_time_cannot_be_after_end_time
    return unless start_date && end_date
    errors.add(:start_date, "Cannot be before end date") if start_date > end_date
  end
end

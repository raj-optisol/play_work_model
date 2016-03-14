class ScheduleData < BaseModel::Data
  include Symbolize::ActiveRecord

  property :start_date, type: Fixnum
  property :end_date, type: Fixnum
  property :name
  property :kind, type: :symbol, default: :regular

  symbolize :kind, in: [:regular, :master]


  validates :name, presence: true
  #validate :start_date_cannot_be_after_end_date

  has_n(:schedules).to(ScheduleData)
  has_n(:rules).to(RuleData)
  has_n(:events).to(EventData)
  has_one(:team).from(TeamData)

  def start_date_cannot_be_after_end_date
    # return unless start_date && end_date
    # errors.add(:start_date, "Cannot be before end date") if start_date > end_date
  end
end

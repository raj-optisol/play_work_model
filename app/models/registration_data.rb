class RegistrationData < BaseModel::Data

  property :name, :kind
  property :cost, type:Float, default: 0.0
  property :is_tryout, :type => :boolean, default: false
  property :start_date, type: Fixnum
  property :end_date, type: Fixnum
  property :start_age,  type: Fixnum
  property :end_age, type: Fixnum 

  has_one(:organization).from(OrganizationData, :registrations)  
  has_n(:participants).from(:registered_for)
  has_n(:volunteers).from(:volunteers_for)
end

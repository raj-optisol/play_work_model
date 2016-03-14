class LocationData < BaseModel::Data

  property :name
  property :address1
  property :address2
  property :city
  property :state
  property :country, default: "U.S.A"
  property :zipcode
  property :latitude
  property :longitude
  property :migrated_id

  property :migrated_phone
  property :migrated_fax

  has_n(:happenings).from(:locations)

  validates :name, presence: true

end

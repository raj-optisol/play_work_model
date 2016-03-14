require 'factory_girl'

FactoryGirl.define do
  sequence(:loc_name) {|n| "Location#{n}"}
  sequence(:street_address) {|n| "#{n}#{n+1}#{n+2} Main St"}
  sequence(:zipcode) {|n| "2820#{n}"}

  factory :location, class: LocationData do
    name {FactoryGirl.generate :loc_name}
    address1 { FactoryGirl.generate :street_address}
    address2 "Suite 200"
    city "Charlotte" 
    state "NC" 
    zipcode {FactoryGirl.generate :zipcode}
    country "U.S.A"
    kyck_id { UUIDTools::UUID.random_create.to_s}
  end
end

def create_location(attrs={})
  dd = FactoryGirl.create(:location, attrs)
  LocationRepository.find(dd.id)
end

def create_location_for_locatable(obj, loc_attrs={}, repo=LocationRepository)
  loc = FactoryGirl.create(:location, loc_attrs)
  loc = repo.find(loc.id)
  
  obj.add_location(loc)
  repo.persist(loc)
end

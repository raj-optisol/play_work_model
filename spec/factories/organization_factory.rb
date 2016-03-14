require 'factory_girl'

FactoryGirl.define do
  sequence(:org_name) {|n| "Club#{n}"}

  factory :club, class: OrganizationData do
    name {FactoryGirl.generate :org_name}
    status :active
    kyck_id { UUIDTools::UUID.random_create.to_s}

  end

end

def create_club(attrs={}, repo = OrganizationRepository)
  od = FactoryGirl.create(:club, attrs)  
  od.save!
  OrganizationRepository.find(od.id)

end

def create_academy
  od = FactoryGirl.create(:club)
  od.save!
  OrganizationRepository.find(od.id)
end


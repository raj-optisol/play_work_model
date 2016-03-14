require 'factory_girl'

FactoryGirl.define do
  sequence(:comp_name) {|n| "Competition#{n}"}

  factory :competition, class: CompetitionData do
    name {FactoryGirl.generate :comp_name}
    start_date {DateTime.now}
    end_date {5.months.from_now}
    kyck_id { UUIDTools::UUID.random_create.to_s}
  end
end

def create_competition(attrs={})
  cd = FactoryGirl.create(:competition)
  cd.save!
  CompetitionRepository.find(cd.id)
end

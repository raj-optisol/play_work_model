require 'factory_girl'

FactoryGirl.define do
  sequence(:div_name) {|n| "Division#{n}"}

  factory :division, class: DivisionData do
    name {FactoryGirl.generate :div_name}
    age '14'
    gender 'm'
    kind 'whatever'
    roster_lock_date {7.days.from_now}
    kyck_id { UUIDTools::UUID.random_create.to_s}
  end
end

def create_division(attrs={})
  dd = FactoryGirl.create(:division)
  dd.save!
  CompetitionRepository::DivisionRepository.find(dd.id)
end

def create_division_for_competition(comp, div_attrs={}, repo=CompetitionRepository)
  default_attrs = FactoryGirl.attributes_for(:division)
  div = comp.create_division(default_attrs.merge(div_attrs))
  repo.persist!(div)
end



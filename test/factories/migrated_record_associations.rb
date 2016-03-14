# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :migrated_record_association do
    migrated_record_id 1
    referential_migrated_record_id 1
    association_name "MyString"
    successful false
  end
end

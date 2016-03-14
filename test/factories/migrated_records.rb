# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :migrated_record do
    original_type "MyString"
    original_id 1
    kyck_id "MyString"
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :duplicate_migrated_record do
    migrated_record_id 1
    additional_id 1
  end
end

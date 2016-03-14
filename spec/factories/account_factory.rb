require 'factory_girl'

FactoryGirl.define do
  factory :account do
    email {FactoryGirl.generate :email}
    kyck_id {UUIDTools::UUID.random_create}
    kind :user

    trait :as_admin do
      kind :admin
    end
  end
end

def create_account(attrs={})
  FactoryGirl.create(:account, attrs)
end



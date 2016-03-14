require 'factory_girl'

FactoryGirl.define do
  sequence(:sanctioning_body_name) {|n| "Sanction_#{n}"}
  factory :sanctioning_body, class: SanctioningBodyData do
    kyck_id { UUIDTools::UUID.random_create.to_s}
    name {FactoryGirl.generate(:sanctioning_body_name)}
  end
end

FactoryGirl.define do
  sequence(:merchant_account_id) {|n| "merchant_#{n}"}
  factory :merchant_account, class: MerchantAccountData do
    kyck_id { UUIDTools::UUID.random_create.to_s}
    merchant_id {FactoryGirl.generate(:merchant_account_id)}
    rate { "0.029" }
    per_transaction { "0.3" }
  end
end


FactoryGirl.define do
  sequence(:state_id) {|n| "state_#{n}"}
  factory :state, class: StateData do
    kyck_id { UUIDTools::UUID.random_create.to_s}
    name {FactoryGirl.generate(:state_id)}
  end
end

def create_sanctioning_body(attrs={})
  sb = FactoryGirl.create(:sanctioning_body, attrs)
  sb.save!
  SanctioningBodyRepository.find(sb.id)
end

def create_sanctioning_body_with_merchant_acct(attrs={}, merchant_attrs={})
  mr = FactoryGirl.create(:merchant_account, merchant_attrs)

  sb = create_sanctioning_body(attrs)
  sb._data.merchant_account = mr
  sb._data.save!
  SanctioningBodyRepository.find(sb.id)
end

def sanctioning_body_create_state(sb, attrs={})
    r = FactoryGirl.create(:state, attrs)
    sb._data.states << r
    SanctioningBodyRepository.persist! sb
    StateRepository.find(r.id)
end

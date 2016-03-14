require 'factory_girl'

FactoryGirl.define do
  sequence(:first_name) {|n| "John#{n}"}
  sequence(:last_name) {|n| "Smith#{n}"}
  sequence(:middle_name) {|n| "Elliott#{n}"}
  sequence(:email) {|n| "john_smith#{n}@email.com"}
  sequence(:phone_number) {|n| "#{n}0#{n}-#{n}#{n}#{n}-1234"}

  factory :user, class: UserData do
    first_name {FactoryGirl.generate :first_name}
    last_name {FactoryGirl.generate :last_name}
    middle_name {FactoryGirl.generate :middle_name}
    email {FactoryGirl.generate(:email).downcase}
    phone_number {FactoryGirl.generate :phone_number}
    kyck_id { UUIDTools::UUID.random_create.to_s}
    permission_sets []
    #organization_requests []


    trait :as_registrar_with_staff do
      permission_sets [PermissionSet::MANAGE_STAFF]
    end

    trait :as_registrar_with_manage_organization do
      permission_sets [PermissionSet::MANAGE_ORGANIZATION]
    end

    trait :as_registrar_with_manage_request do
      permission_sets [PermissionSet::MANAGE_REQUEST]
    end

    trait :as_registrar_with_manage_money do
      permission_sets [PermissionSet::MANAGE_MONEY]
    end
  end
end

def regular_user(attrs={}, repo=UserRepository)
  ud = FactoryGirl.create(:user, attrs)
  ud.save!
  UserRepository.find(ud.id)
  # props.delete("permission_sets")
  # ud = User.build(props)
  # repo.persist(ud)
end

def admin_user(permission_sets=[])
  ud = FactoryGirl.create(:user, kind: :admin, permission_sets: permission_sets)
  ud.save!
  UserRepository.find(ud.id)
end

def add_user_to_org(user, org, attrs={}, repo=UserRepository)
  s = org.add_staff(user, attrs)
  repo.persist!(user)
  s
end

def add_user_to_obj(user, obj, attrs={})
  obj.add_staff(user, attrs)
  UserRepository.persist!(user)
end



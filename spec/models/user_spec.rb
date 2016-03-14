require 'spec_helper'
require_relative '../../app/models/user'

describe User do

  let(:user){regular_user(email: 'test@test.com', first_name: 'First', last_name: 'Last')  }

  describe "#full_name" do
    it "should return first_name and last_name separated by a space" do
      user.full_name.should == "#{user.first_name} #{user.middle_name} #{user.last_name}"
    end

    context "when the user has no middle name" do

        it "returns first and last separated by a space" do
          user.middle_name = ""
          user.full_name.should == "#{user.first_name} #{user.last_name}"
        end

        it "returns first and last separated by a space" do
          user.middle_name = nil
          user.full_name.should == "#{user.first_name} #{user.last_name}"
        end

    end
  end

  describe "#name" do
    it "should return first_name and last_name separated by a space" do
      user.name.should == "#{user.first_name} #{user.middle_name} #{user.last_name}"
    end

    context "when the user has no middle name" do

        it "returns first and last separated by a space" do
          user.middle_name = ""
          user.name.should == "#{user.first_name} #{user.last_name}"
        end

        it "returns first and last separated by a space" do
          user.middle_name = nil
          user.name.should == "#{user.first_name} #{user.last_name}"
        end

    end
  end

  describe "#admin?" do
    it "should return true for admins" do
      user.kind = "admin"
      user.admin?.should be_true
    end
  end

  describe "#add_user" do
    it "should add an account" do

      blah = user.add_user(regular_user, {:confirmed => false})
      UserRepository.persist(blah)
      user.accounts.count.should == 1
    end
  end

  describe "#confirmed_accounts" do
    it "should show only confirmed accounts" do

      user.add_user(regular_user, {:confirmed => true})
      user.add_user(regular_user, {:confirmed => false})
      UserRepository.persist user

      user.confirmed_accounts.count.should == 1
    end
  end

end

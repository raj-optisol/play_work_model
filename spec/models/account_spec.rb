require 'spec_helper'

describe Account do
  describe "#claimed?" do
    let(:account) {FactoryGirl.create(:account)}
    it "should be true for accounts with a sign_in_count" do
      account.sign_in_count = 1
      account.claimed?.should be_true
    end

    it "should be false for accounts without a kyck id" do
      account.claimed?.should be_false
    end
  end
end

require 'spec_helper'

describe "Staff" do
  
  describe "#valid?" do
    let(:user) {regular_user}
    let(:org) {create_club}

    it "is false if the user does not have an email" do
      user.email=nil
      s = org.add_staff(user)
      s.valid?.should be_false
    end

    it "adds user errors to staff errors" do
      user.email=nil
      s = org.add_staff(user)
      s.valid?
      s.errors[:email].should == ["can't be blank"]
    end
  end
end

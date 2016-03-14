require 'spec_helper'

describe HomeController, type: :controller do

  before(:each) do
    @user = regular_user
    sign_in_user(@user)
  end

  describe "#profile" do
    it "returns the current user info" do
      get :profile, format: :json
      json["id"].should == @user.kyck_id.to_s
    end
  end


end

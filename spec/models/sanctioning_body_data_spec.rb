require 'spec_helper'

describe SanctioningBodyData do
  
  context "saving" do
  
    it "should create a kyck_id" do
      sb = SanctioningBodyData.create!(name: 'Bucketts') 
      sb.kyck_id.should_not be_nil
    end
  
  end
end

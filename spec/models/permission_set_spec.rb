require 'spec_helper'

describe PermissionSet do
  describe ".for_staff" do
    
    it "should include ManageStaff" do
      PermissionSet.for_staff.should include(PermissionSet::MANAGE_STAFF) 
    end
  end
end

require_relative '../../app/models/empowerable'


describe Empowerable do

  subject{ 
  
    os = OpenStruct.new()
    os.permission_sets = []
    os.extend(Empowerable::Check)
  }
  describe "Writing to permisson sets" do
  
    it "should change the permission_sets" do
      subject.permission_sets = ["New Permission"] 
      subject.permission_sets.should == ["New Permission"] 
    end

    it "should append new permission sets" do
      subject.permission_sets = ["New Permission"] 
      subject.permission_sets << "Another PS"
      subject.permission_sets.should == ["New Permission", "Another PS"] 
    end

  end

  describe "#has_any_permission?" do

    describe "when the requested permission_sets intersect" do
      before(:each) do
        subject.permission_sets << "ManageStaff"
        subject.permission_sets << "ManageMoney"
      end

      it "should return true " do
        subject.has_any_permission?("ManageStaff").should == true    
        subject.has_any_permission?("ManageMoney").should == true    
        subject.has_any_permission?("ManageMoney", "ManageStaff").should == true    
        subject.has_any_permission?(*[ "ManageOrganization","ManageStaff" ]).should == true    
      end
    end

    describe "when the requested permission_sets do not intersect" do
      before(:each) do
        subject.permission_sets << "ManageStaff"
        subject.permission_sets << "ManageMoney"
      end

      it "should return false" do
        subject.has_any_permission?("ManageRequest").should == false
        subject.has_any_permission?([ "ManageRequest", "ManageOrganization" ]).should == false
      end
    end

    describe "when the object has no permissions" do
      it "should return false" do
        subject.has_any_permission?("ManageRequest").should == false
        subject.has_any_permission?("ManageRequest", "ManageOrganization").should == false
      end
    end

  end
end

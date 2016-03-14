require 'spec_helper'

describe StaffRepresenter do
 
  before(:each) {
    @user = regular_user  
    od = FactoryGirl.create(:club)
    @org = OrganizationRepository.find(od.id) 

    @staff = @org.add_staff(@user, {title: "Coach", permission_sets:  ['ManageStaff']})
    @staff._data.save

    UserRepository.persist @user
    OrganizationRepository.persist @org
    
    @user._data.__java_obj.load
    @staff = @org.get_staff.first    
  }

  describe "#.to_json" do
    subject{ JSON.parse(@staff.extend(StaffRepresenter).to_json)}

    %w(title email).each do |attr|
      it "should include the #{attr}" do
        subject[attr].should == @staff.send(attr) 
      end
    end

    it "should include the organization" do
      subject["staffed_item"]["id"].should == @org.kyck_id.to_s
    end

    it "should include the phone number" do
      subject["phone_number"].should == @user.phone_number 
    end
     
  end
end

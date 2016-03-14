require 'spec_helper'
load 'support/active_model_lint.rb'

describe Organization do
  let(:org){create_club}

  it_should_behave_like "ActiveModel" 
  describe "validations" do
    it "is invalid without a name" do
      org.name= nil
      org.valid?.should be_false
    end    
  end
  
   describe "#add_staff" do 
     before(:each) do
       @user = regular_user
     end
  
     it "should only add one" do
       assert_difference lambda {org.get_staff().count} do
         staff = org.add_staff(@user, { title: 'Coach' })
         OrganizationRepository.persist org
       end
     end
  
     it "should not allow duplicates" do
       org.add_staff(@user, {title: 'Coach'})
       OrganizationRepository.persist org
       @user._data.reload
       assert_no_difference lambda {org.get_staff().count} do
         staff = org.add_staff(@user, {title: 'Coach'})
         OrganizationRepository.persist org
       end
     end
   end
  
   describe "#get_staff" do
     before(:each) do
       @user = regular_user
       @staff = org.add_staff(@user, { title: 'Coach' })
       OrganizationRepository.persist org
     end
  
     it "returns the staff for the organization" do
       org.get_staff().first.id.should == @staff.id
     end
  
   end
  
   describe "#get_staff_for_user" do
     before(:each) do
       @user = regular_user
       @staff = org.add_staff(@user, { title: 'Coach' })
       OrganizationRepository.persist org
       @user._data.reload
     end
  
     it "returns the staff for the user" do
       org.get_staff_for_user(@user).id.should == @staff.id
     end
  
   end
  
   describe "#remove_staff" do 
     before(:each) do
       @user = regular_user
       org.add_staff(@user, { title: 'Coach' })
       OrganizationRepository.persist org
       @user._data.reload
     end
  
     it "should remove the relatioship" do
       assert_difference lambda {org.get_staff().count}, -1 do
         org.remove_staff(@user)
         org._data.reload
         OrganizationRepository.persist org
       end
     end
  
   end
  
end

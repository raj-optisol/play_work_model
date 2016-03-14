require 'spec_helper'

describe KyckRegistrar::Actions::CreateOrganization do

  subject {KyckRegistrar::Actions::CreateOrganization.new( user ) }

  let(:user) {regular_user}
  let(:input) { 
    {  
      :name => 'North Meck 1', 
      :address1 => "123 blah", 
      :city => "CLT", 
      :state => 'NC', 
      :zipcode => "28203", 
      :phone_number => "1234567899"}.with_indifferent_access
  }

  it "should add the requestor to the staff" do
    result = subject.execute input
    result.get_staff.count.should == 1
  end

  it "creates a location for the organization" do
    result = subject.execute input

    result.locations.count.should == 1
    result.locations.first.address1.should == "123 blah"
    result.locations.first.city.should == "CLT"
    result.locations.first.zipcode.should == "28203"
    result.locations.first.kyck_id.should_not be_nil
  end

  it "broadcasts an new organziation" do
    listener = double('listener')
    listener.should_receive(:organization_created).with instance_of Organization
    subject.subscribe(listener)

    subject.execute(input)
  end


  context "when the organzation is not valid" do
    let(:input) {{
      :address1 => "123 blah", 
      :city => "CLT", 
      :state => 'NC', 
      :zipcode => "28203", 
      :phone_number => "1234567899"} 
    }

    it "returns the organization with errors" do
      result = subject.execute input
     1.should == 1
    end


    it "broadcasts an invalid organziation" do
      listener = double('listener')
      listener.should_receive(:invalid_organization).with instance_of Organization
      subject.subscribe(listener)

      subject.execute(input)
    end

  end


end

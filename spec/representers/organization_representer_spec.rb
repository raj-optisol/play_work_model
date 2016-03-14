require 'spec_helper'

describe OrganizationRepresenter do
  let(:org) { create_club} 
  subject { org.extend(described_class)}

  it "has id" do
    JSON.parse(subject.to_json)["id"].should == org.id
  end

  %w( name url email phone_number  permissions ).each do |attr|
    it "has #{attr}" do

      JSON.parse(subject.to_json)[attr].should == org.public_send(attr)
    end
  end

  it "has a default avatar" do
    JSON.parse(subject.to_json)["avatar_url"].should == "https://res.cloudinary.com/kyck-com/image/upload/default_organization_avatar_i68wap.png"
  end

  context "when the organzation has an avatar" do
    let(:org) {create_club(avatar: 'avatar')}
 
    it "has a path to the right avatar" do
      JSON.parse(subject.to_json)["avatar_url"].should == "https://res.cloudinary.com/kyck-com/image/upload/avatar.png"
    end
    
  
  end
end

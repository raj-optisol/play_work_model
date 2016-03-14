require 'spec_helper'

describe Note do
  
  describe "attribution" do
    subject{described_class.new}
    it "has text" do
      subject.text = "I am a note"
      subject.text.should == "I am a note"
    end

    it "has an author" do
      user = regular_user
      subject.author = user
      subject.author.id.should == user.id
    end

    it "has a target" do
      org = create_club
      subject.target = org
      subject.target.id.should == org.id
    end
  end
end

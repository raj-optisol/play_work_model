require 'spec_helper'
describe CardData do
 
  describe "attributes" do

    it "includes user name attributes" do
      c = CardData.new(first_name: 'Bob', middle_name:'Jim', last_name:'Barker')  
      c.first_name.should == 'Bob'
      c.last_name.should == 'Barker'
      c.middle_name.should == 'Jim'
    end

    it "includes birthdate" do
      time = 8.years.ago
      c = CardData.new(birthdate: time)  
      c.birthdate.should == time.to_date
    end

  end
end

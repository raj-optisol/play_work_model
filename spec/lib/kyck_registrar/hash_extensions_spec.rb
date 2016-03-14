require 'spec_helper'
module KyckRegistrar
  describe HashExtensions do
    describe "#symbolize_keys" do
      subject{
        {"key1" => "val1", "another_key" => "another_val"}
      }

      it "should return the keys as symbols" do
        subject.symbolize_keys[:key1].should == "val1"  
        subject.symbolize_keys[:another_key].should == "another_val"
      end
    end
  end
end

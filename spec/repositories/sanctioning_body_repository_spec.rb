require 'spec_helper'

describe SanctioningBodyRepository do

  describe "#find_by_name" do
    before(:each) do
      sb = SanctioningBody.build(name: 'USCS')
      described_class.persist(sb) 
    end

    it "finds the sanctioning body" do
      sb = described_class.find_by_name("USCS") 
      sb.should_not be_nil
    end
  end
end

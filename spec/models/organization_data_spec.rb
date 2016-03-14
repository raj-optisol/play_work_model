require 'spec_helper'

describe OrganizationData do
  
  describe "validation" do
    
    context "when a name has already been taken" do
      let(:club) { create_club}

      it "is not valid" do
        dup = Organization.build(name: club.name)  
        dup.should_not be_valid
      end
    
    end

    context "kind" do

      let(:club) { create_club }

      it "is invalid with an unallowed kind" do
        club.kind= :invalid
        expect(club.valid?).to eq(false)
      end

      it "is valid with an allowed kind" do
        club.kind = OrganizationData::ORG_KINDS.sample
        expect(club.valid?).to eq(true)
      end
    end

  end
end

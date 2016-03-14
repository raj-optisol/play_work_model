require 'spec_helper'

module KyckRegistrar
  module Actions
    describe LocationAction do

      describe "location data validity" do
        
        let(:location_attributes) do
          {
            address1: "1 Test St.",
            city: "Testville",
            state: "NC",
            zipcode: "11111"
          }.with_indifferent_access
        end 
        let(:subject) { LocationAction.extend(LocationAction) }

        context "with invalid data" do
          before(:each) do
            @key = location_attributes.keys.sample
            location_attributes.delete(@key)
          end

          it "returns false" do
            expect(subject.location_data_valid?(location_attributes)).to be_false
          end

          it "returns a correct error message" do
            expect(subject.location_data_errors(location_attributes)).to eq({@key.to_sym => ["is required"]})
          end

        end

        context "with valid data" do
          it "returns true" do
            expect(subject.location_data_valid?(location_attributes)).to be_true
          end
        end

      end

    end
  end
end



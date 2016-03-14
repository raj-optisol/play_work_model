require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateLocation do
      let(:requestor)  {regular_user} 
      let(:club) {create_club}

      describe "#initialize" do
        it "takes a user and org" do
          expect {described_class.new(requestor, club)}.to_not raise_error
        end
      end

      describe "execute" do
        subject {described_class.new(requestor, club)}
        let(:location_attributes) {
          {
            name: 'Location',
            address1: '123 Main Street',
            address2: 'Suite 500',
            city: 'Charlotte',
            state: 'NC',
            zipcode: '28282',
            country: 'USA'

          }
        }

        context "when the user has permission" do
          before do
            subject.stub(:is_permissible?) {true}
          end

          it "adds a new location to the club" do
            expect{subject.execute(location_attributes)}.to change {club.locations.count}.by(1)
          end

          it "broadcasts success" do
            listener = double('listener')
            listener.should_receive(:location_created).with instance_of Location
            subject.subscribe(listener)
            subject.execute(location_attributes)
          end

          context "when the location is in valid" do

            it "broadcasts invalid location" do
              location_attributes.delete(:name) 
              listener = double('listener')
              listener.should_receive(:invalid_location).with instance_of Location
              subject.subscribe(listener)
              subject.execute(location_attributes)
            end   

          end
        end

      end
    end
  end
end

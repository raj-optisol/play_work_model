require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateSanctioningBody do
      let(:sanctioning_body) { create_sanctioning_body }
      let(:requestor) { regular_user }
      subject { described_class.new(requestor, sanctioning_body.kyck_id)}

      describe "#initialize" do
        it "takes a requestor and a sanctioning_body" do
          expect {subject}.to_not raise_error
        end
      end

      describe "#execute" do
        context "when the requestor has the right permissions" do
          let(:update_params) {
            {
              name: 'New Name', 
              url: 'http://newname.info', 
              avatar:'1234',
              address1: '123 Main', 
              address2: 'suite 200', 
              city: "Soccertown", 
              state:"NC",
              zipcode: '12345', 
              country: 'USA',
              phone_number: '123-456-7890',
              fax_number: '098-765-4321'
            }.with_indifferent_access
          }
          before(:each) do
            SanctioningBodyRepository.all.each { |sb| sb._data.destroy}
            add_user_to_org(requestor, sanctioning_body, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]})
          end

          it "updates the sanctioning_body" do
            result = subject.execute(update_params)
            result.name.should == "New Name"
            result.url.should == "http://newname.info"
            result.avatar.should == "1234"
          end

          it "updates the address fields" do
            result = subject.execute(update_params)
            %w(address1 address2 city state zipcode country).each do |attr|
              result.locations.first.send(attr).should == update_params[attr.to_sym]
            end
            
          end
        end

        context "when the requestor does not have the right permissions" do
          it "raises an error" do
            expect { subject.execute({})}.to raise_error PermissionsError
            
          end
        end
      end
    end
  end
end

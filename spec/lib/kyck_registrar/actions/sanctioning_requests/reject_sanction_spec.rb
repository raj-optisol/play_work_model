require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RejectSanction do
      let(:sanctioning_body) {create_sanctioning_body}

      describe "initialize" do
        it "takes a requestor and a sanctioning body" do
          expect {described_class.new(regular_user, sanctioning_body)}.to_not raise_error
        end
      end

      describe "#execute" do
        let(:requestor) { regular_user}
        let(:org) {create_club}
        let(:sanctioning_request) { create_sanctioning_request(sanctioning_body, org, requestor)}
        let(:input) { { id: sanctioning_request.id } }

        subject{described_class.new(requestor, sanctioning_body)}

        context "when the requestor has permission" do
          before(:each) do
            add_user_to_org(requestor, sanctioning_body, {title: 'Admin',permission_sets: [PermissionSet::MANAGE_REQUEST] })
          end

          it "denies the request" do
            sa = subject.execute(input)
            sa.status.should == :denied
          end

          it "publishes denial event" do
            listener = double('listener')
            listener.should_receive(:sanctioning_request_denied).with instance_of SanctioningRequest
            subject.subscribe(listener)

            subject.execute(input)
          end

        end

        context "when the requestor does not have permission" do
        
          it "raises an error" do
            expect {subject.execute(input)}.to raise_error PermissionsError
          end
        
        end
      end
    end
  end
end

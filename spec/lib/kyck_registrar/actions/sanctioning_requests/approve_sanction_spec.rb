require 'spec_helper'

module KyckRegistrar
  module Actions
    describe ApproveSanction do
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
        let(:input) { { kyck_id: sanctioning_request.kyck_id } }

        subject{described_class.new(requestor, sanctioning_body)}

        context "when the requestor has permission" do
          before(:each) do
            sanctioning_request
            add_user_to_org(requestor, sanctioning_body, {title: 'Admin',permission_sets: [PermissionSet::MANAGE_REQUEST] })
            @state = sanctioning_body_create_state(sanctioning_body)
          end

          it "approves the request" do
            sa = subject.execute(input)
            sa.status.should == :approved
          end

          # it "adds organization to state" do
          #   sa = subject.execute({kyck_id:sanctioning_request.kyck_id, region_id:@region.kyck_id})
          #   sa.status.should == :approved
          #   org.sb_region.kyck_id.should == @region.kyck_id
          # end

          it "publishes approval event" do
            listener = double('listener')
            listener.should_receive(:sanctioning_request_approved).with instance_of SanctioningRequest
            subject.subscribe(listener)

            subject.execute(input)
          end

          it "creates the sanctioned relationship from sb to org" do
            subject.execute(input)
            sanctioning_body.sanctions.map(&:id).should include org.id
          end

          it "sends a notifcation" do
            notifier = Object.new
            notifier.should_receive(:sanctioning_request_approved)
            subject.notifier = notifier
            subject.should_not_receive(:broadcast).with(:notification_failed, anything)

            subject.execute(input)
          end

          context "when the notification fails" do
            it "brodcasts a message" do
              listener = double('listener')
              listener.should_receive(:notification_failed)
              notifier = Object.new
              notifier.stub(:sanctioning_request_approved).and_raise StandardError
              subject.subscribe(listener)
              subject.notifier = notifier

              subject.execute(input)
            end

          end

          context "for a competition" do
            let(:league) {create_competition}
            let(:sanctioning_request) { create_sanctioning_request(sanctioning_body, league, requestor)}

            it "creates the sanctioned relationship from sb to competition" do
              subject.execute(input)
              sanctioning_body.sanctions.map(&:id).should include league.id
            end
          end

          context "when the salesrep is found" do
            let(:sales_rep) { regular_user }

            it "sets it on the sanction" do
              input[:salesrep] = sales_rep.kyck_id
              subject.execute(input)
              Oriented.graph.commit
              org._data.reload
              assert_not_nil org.sb_rep
            end
          end

          context "when the sales rep is not found" do
            it "still approves the sanction" do
              input[:salesrep] = "notreal"
              result = subject.execute(input)
              result.status.should == :approved
            end
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

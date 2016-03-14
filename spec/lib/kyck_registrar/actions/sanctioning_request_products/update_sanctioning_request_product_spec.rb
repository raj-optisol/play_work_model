require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateSanctioningRequestProduct do
      let(:sanctioning_body) { create_sanctioning_body }
      let(:srp) { create_sanctioning_request_product(sanctioning_body) }
      let(:requestor) { regular_user }
      subject { described_class.new(requestor, srp, sanctioning_body)}

      describe "#initialize" do
        it "takes a requestor and a sanctioning_body" do
          expect {subject}.to_not raise_error
        end
      end

      describe "#execute" do
        context "when the requestor has the right permissions" do
          before(:each) do
            sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_MONEY]})
            UserRepository.persist!(requestor)
          end

          it "updates the sanctioning_request_product" do
            result = subject.execute({kind: 'academy', amount: 300.0, active: true})
            result.kind.should == :academy
            result.amount.should == 300.0
            result.active.should == true
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

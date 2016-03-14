require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetSanctioningRequestProducts do

      let(:requestor) {regular_user}
      let(:uscs) {create_sanctioning_body}

      describe "#execute" do
        context "when the sb has one" do
          subject {described_class.new(requestor, uscs)}

          before do
           @srp = SanctioningRequestProduct.build(sanctioning_body_id: uscs.kyck_id, amount: 1000.00, kind: :club, active: true)
           SanctioningRequestProductRepository.persist!(@srp)
          end

          it "returns them" do
            prods = subject.execute
            prods.count.should == 1
          end

        end
      end
    end
  end
end

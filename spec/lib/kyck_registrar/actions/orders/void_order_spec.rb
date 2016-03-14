require 'spec_helper'

module KyckRegistrar
  module Actions
    describe VoidOrder do
      let(:requestor) { regular_user }
      let(:payer) { create_sanctioning_body }
      let(:payee) { create_club }
      let(:order) { create_order(regular_user, payer, payee, status: :submitted) }
      let(:payment_account) { PaymentAccount.build(obj_type: payer.class.to_s, obj_id: payer.kyck_id, balance: 10000) }
      let(:transaction) { create_payment_transaction(payment_account.id, order.id) }

      subject { described_class.new(requestor, order) }

      describe "#execute" do
        context "when the user has permission" do

          let(:pg_stub) { Object.new }

          before do
            add_user_to_org(requestor, payee, permission_sets: [PermissionSet::MANAGE_MONEY])
          end

          it "voids the order" do
            pg_stub.should_receive(:void).with(transaction.transaction_id)
            subject.payment_gateway = pg_stub
            subject.execute
          end

          it "marks the order payment status as voided" do
            subject.payment_gateway = pg_stub
            subject.execute
            expect(order.payment_status).to eq(:voided)
          end

          context "when the order is not submitted" do
            let(:order) { create_order(regular_user, payer, payee, status: :completed) }

            it "raises an error" do
              expect { subject.execute }.to raise_error OrderNotEligibleForVoid
            end
          end
        end

        context "when the user does not have permission" do
          it "raises a permission error" do
            expect { subject.execute }.to raise_error PermissionsError
          end
        end
      end
    end
  end
end

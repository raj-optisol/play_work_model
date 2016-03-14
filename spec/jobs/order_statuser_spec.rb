require 'spec_helper'

module Jobs
  describe OrderStatuser do

    let(:issuer) {regular_user}
    let(:payer) {create_club}
    let(:payee) {create_sanctioning_body}
    let(:btree) {Object.new}

    let(:order) { create_order(issuer, payer, payee, status: :submitted, payment_status: :authorized)}
    let(:payment_account) {
      pa = PaymentAccount.build(obj_type: payer.class.to_s, obj_id: payer.kyck_id, balance: 10000)
    }
    let(:transaction) { create_payment_transaction(payment_account.id, order.id) }

    subject {described_class.new}

    describe "#execute" do

      before do
        transaction
        subject.payment_gateway = btree 
      end

      context "for authorized orders" do

        it "asks Braintree for the status of transactions on the order" do
          btree.should_receive(:find).with(transaction.transaction_id).and_return(OpenStruct.new(status: 'settled'))
          subject.run
        end

        it "sets the order status to settled" do
          btree.stub(:find).with(transaction.transaction_id).and_return(OpenStruct.new(status: 'settled'))
          subject.run
          order._data.reload
          order.payment_status.should == :settled
        end

      end

      context "for newly held  orders" do
        let(:order) { create_order(issuer, payer, payee, status: :submitted, payment_status: :settled)}
        let(:result) {Object.new}
        before do
          result.stub(:success?){true}
          btree.stub(:find).with(transaction.transaction_id).and_return(OpenStruct.new(status: 'settled', escrow_status:'held'))
          btree.should_receive(:release_from_escrow).with(transaction.transaction_id).and_return(result)
        end

        it "sets the order status to completed" do
          subject.run
          order._data.reload
          order.payment_status.should == :completed
        end

        it "sets the transaction to released" do
          subject.run
          transaction._data.reload
          transaction.status.should == "released"
        end
      end

      context "when an error happens" do

        it "sends it to Raven" do
          btree.stub(:find).with(transaction.transaction_id).and_raise(StandardError.new("Something pooed"))
          Raven.should_receive(:capture_exception)
          subject.run

        end


      end
    end
  end
end

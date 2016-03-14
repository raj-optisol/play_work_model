require 'spec_helper'

module Orders
  describe TransactionSummaryCell do

    context "cell instance" do
      subject { cell("orders/transaction_summary") }

      it 'should respond to show' do
        # Given the new API which does not set the context to the cell itself
        # but rather to a wrapper with a method_missing definition that
        # delegates to the cell, which is a private instance variable thereof,
        # this is the only way I could reasonably test that the cell does
        # in fact implement the method in question. It will still raise an
        # ArgumentError, but if the method were entirely absent it would
        # raise a NoMethodError, and so we check for the exclusion of that
        # particular exception
        expect { show }.not_to raise_error NoMethodError
      end
    end

    context "cell rendering" do
      let(:cp1) {create_card_product(payee, age: 18)}
      let(:cp2) {create_card_product(payee, age: 14)}
      let(:initiator) {regular_user}
      let(:payee) { create_sanctioning_body}
      let(:payer) {create_club}
      let(:order) {
        create_order(initiator, payer, payee )      
      }

      before do
        order.add_order_item(product_for_obj_id: '1234', product_for_obj_type: 'User', amount: 15.0, product_id: cp1.id, product_type: cp1.class.to_s)    
        order.add_order_item(product_for_obj_id: '234', product_for_obj_type: 'User', amount: 15.0, product_id: cp1.id, product_type: cp1.class.to_s)    
        order.add_order_item(product_for_obj_id: '2344', product_for_obj_type: 'User', amount: 15.0, product_id: cp2.id, product_type: cp2.class.to_s)    
        order.amount = 45.00
        OrderRepository.persist order

        
      end

      context "rendering show" do
        subject { render_cell("orders/transaction_summary", :show, order: order, payee_name: 'USCS', payer_name: 'Club', payer_account_balance: 10) }

        it { should have_selector("div.invoice-total") }

      end
    end

  end
end

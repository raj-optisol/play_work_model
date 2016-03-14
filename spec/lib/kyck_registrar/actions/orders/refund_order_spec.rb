require 'spec_helper'

describe KyckRegistrar::Actions::RefundOrder do

  # describe "#new" do
  #   it "takes a requestor" do
  #     expect{described_class.new}.to raise_error ArgumentError
  #   end
  #
  #   it "takes an order" do
  #     expect{described_class.new(User.new)}.to raise_error ArgumentError
  #   end
  # end

  let(:requestor) { regular_user }
  let(:org) { create_club }
  let(:sb) { create_sanctioning_body }
  let(:sr) { create_sanctioning_request(org, sb, requestor, {status: :pending_payment }) }


  let(:srp) {
    attrs = {:kind => 'competition', :amount=>1000.0, :sanctioning_body_id => sb.kyck_id}
    req = SanctioningRequestProduct.build(attrs)
    SanctioningRequestProductRepository.persist req
  }


  before(:each) do
    @charge_card = Object.new
    charge = double()
    charge.stub(:id) { "ch_1UpanTGIDzbBb3" }
    charge.stub_chain(:credit_card_details, :last_4).and_return("4242")
    charge.stub(:refund).and_return(charge)

    refund = double()
    refund.stub(:transaction).and_return(charge)
    refund.stub(:success?).and_return(true)
    @charge_card.stub(:retrieve).and_return(charge)
    @charge_card.stub(:refund).and_return(refund)
    @charge_card.stub(:success?).and_return(true)

    # Stripe.api_key = Settings.stripe.api_key

    @token = "tok_1UpanTGIDzbBb3"
    @customer = double()
    @customer.stub(:id) { "cu_1UpanTGIDzbBb3" }
    @customer.stub_chain(:active_card, :last4).and_return("4242")
  end

  context 'uscs admin refunding organization request' do

    let(:payment_account){
      @pa = PaymentAccount.build(:obj_id=>org.kyck_id, :obj_type=>org.class.to_s, :balance => 1000)
      PaymentAccountRepository.persist @pa
    }

    # let(:order) {
    #     attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', amount: 1000.0}
    #     order = Order.build(attrs)
    #     OrderRepository.persist order
    # }

    let(:order) {
      attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', status: :completed, amount: 1000.0, payment_status: :completed}
      order = Order.build(attrs)
      OrderRepository.persist! order
    }

    before(:each) do
      add_user_to_obj(requestor, sb, {permission_sets:[PermissionSet::MANAGE_MONEY]})

      oi = order.add_order_item(:product_for_obj_id=> sr.kyck_id, :product_for_obj_type=> sr.class.to_s, :amount=>srp.amount, :product_id => srp.id, :product_type =>srp.class.to_s, :description => 'Sanctioning Request')
      OrderRepository.persist! order

      sr.order_id = order.id
      SanctioningRequestRepository.persist sr

      create_payment_transaction (payment_account.id)

    end

    it 'should refund entire order and mark order payment status as refunded' do

      action = described_class.new requestor, order
      action.charge_method = @charge_card
      input = {}
      result = action.execute input

      result.payment_status.should == :refunded

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 0.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'}).first
      transaction.status.should == "refunded"
      transaction.kind.should == "liability"
      transaction.transaction_type.should == "debit"
      transaction.amount.to_f.should == 1000.0

    end

    context "when the order is not settled or completed" do
      let(:order) {
        attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', status: :completed, amount: 1000.0, payment_status: :authorized}
        order = Order.build(attrs)
        OrderRepository.persist! order
      }

       it "voids the order" do
          charge = double()
          charge.stub(:id) { "ch_1UpanTGIDzbBb3" }
          charge.stub_chain(:credit_card_details, :last_4).and_return("4242")
          charge.stub(:refund).and_return(charge)
          refund = double()
          refund.stub(:transaction).and_return(charge)
          refund.stub(:success?).and_return(true)
          action = described_class.new requestor, order
          @charge_card.should_receive(:void).and_return(refund)
          action.charge_method = @charge_card
          input = {}
          result = action.execute input
       end

    end

    context "when the order is settled" do
      let(:order) {
        attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', status: :completed, amount: 1000.0, payment_status: :settled}
        order = Order.build(attrs)
        OrderRepository.persist! order
      }

       it "refunds the order" do
          charge = double()
          charge.stub(:id) { "ch_1UpanTGIDzbBb3" }
          charge.stub_chain(:credit_card_details, :last_4).and_return("4242")
          charge.stub(:refund).and_return(charge)
          refund = double()
          refund.stub(:transaction).and_return(charge)
          refund.stub(:success?).and_return(true)
          action = described_class.new requestor, order
          @charge_card.should_receive(:refund).and_return(refund)
          action.charge_method = @charge_card
          input = {}
          result = action.execute input
       end

    end

    it 'should refund part of the order' do

      action = described_class.new requestor, order
      action.charge_method = @charge_card
      input = {:refund_amount=>400}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 600.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'}).first
      transaction.status.should == "refunded"
      transaction.kind.should == "liability"
      transaction.transaction_type.should == "debit"
    end

  end

  context 'refunding an order for an organization' do
    let(:order) {
      attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'deposit', status: :completed, amount: 1000.0, payment_status: :completed}
      order = Order.build(attrs)
      OrderRepository.persist! order
    }

    let(:order2) {
      attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: :card_request, status: :completed, amount: 1500.0, payment_status: :completed}
      order = Order.build(attrs)
      OrderRepository.persist! order
    }

    let(:payment_account){
      @pa = PaymentAccount.build(:obj_id=>org.kyck_id, :obj_type=>org.class.to_s, :balance => 0)
      PaymentAccountRepository.persist @pa
    }

    before(:each) do
      add_user_to_obj(requestor, sb, {permission_sets:[PermissionSet::MANAGE_MONEY]})

      ## SANCTIONING REQUEST ORDER (deposit)
      oi = order.add_order_item(:product_for_obj_id=> sr.kyck_id, :product_for_obj_type=> sr.class.to_s, :amount=>srp.amount, :product_id => srp.id, :product_type =>srp.class.to_s, :description => 'Sanctioning Request')
      OrderRepository.persist! order
      create_payment_transaction(payment_account.id, order.id)


      ### CARD REQUEST ORDER  (cart)
      @item1 = order2.add_order_item(:amount=>500, :product_id => create_uuid, :product_type =>'CardProduct', :description => 'Card Request')
      OrderRepository.persist! order2
      @item2 = order2.add_order_item(:amount=>400, :product_id => create_uuid, :product_type =>'CardProduct', :description => 'Card Request')
      OrderRepository.persist! order2
      @item3 = order2.add_order_item(:amount=>600, :product_id => create_uuid, :product_type =>'CardProduct', :description => 'Card Request')
      OrderRepository.persist! order2


      create_withdraw_transaction(payment_account.id, order2.id, 1000)
      create_revenue_transaction(payment_account.id, order2.id, 500)

    end

    it 'should refund entire order and mark order payment status as refunded' do

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {}
      result = action.execute input

      result.payment_status.should == :refunded

      pa = PaymentAccountRepository.find(payment_account.id)

      pa.balance.to_f.should == 1000.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      transaction.count.should == 2
      amt = 0
      transaction.each {|t| amt += t.amount;}
      amt.should == 1500.0

    end

    it 'should refund part of the order' do

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:refund_amount=>300}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 300.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      transaction.count.should == 1
      transaction.first.amount.to_f.should == 300.0

    end

    it 'should refund part of the order returning 2 transactions' do

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:refund_amount=>1100}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 1000.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      transaction.count.should == 2
      amt = 0
      transaction.each {|t| amt += t.amount;}
      amt.should == 1100.0

    end

    it 'should refund only 1 order item and mark item status as refunded' do

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:order_items=>[@item1.id]}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == @item1.amount
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      @item1._data.reload().status.should == "refunded"
      transaction.count.should == 1
      transaction.first.amount.should == @item1.amount

    end

    it 'should refund 2 order items and mark items status as refunded' do

      action = KyckRegistrar::Actions::RefundOrder.new requestor, order2
      action.charge_method = @charge_card
      input = {:order_items=>[@item1.id, @item3.id]}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 1000.0
      transaction = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      @item1._data.reload().status.should == "refunded"
      @item3._data.reload().status.should == "refunded"
      transaction.count.should == 2
      amt = 0
      transaction.each {|t| amt += t.amount;}
      amt.should == @item1.amount+@item3.amount

    end

    it 'should set the refunded_amount on 2 transactions' do

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:refund_amount=>1100}
      result = action.execute input
      transactions = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status_dne=>'refunded'})
      transactions.each {|t|
        if t.transaction_id==nil
          t.refunded_amount.should == 1000
        else
          t.refunded_amount.should == 100
        end
      }
    end
    it 'should set the refunded_amount on 3 transactions' do


      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:refund_amount=>1100}
      result = action.execute input

      action = described_class.new requestor, order2
      action.charge_method = @charge_card
      input = {:refund_amount=>300}
      result = action.execute input

      result.status.should == :completed

      pa = PaymentAccountRepository.find(payment_account.id)
      pa.balance.to_f.should == 1000.0

      transactions = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status_dne=>'refunded'})
      refunded_amount = 0;
      transactions.each {|t| refunded_amount+=t.refunded_amount; }
      refunded_amount.should == 1400.0


      transaction_refunds = AccountTransactionRepository.find_by_attrs({:order_id=>result.id, :status=>'refunded'})
      amt = 0
      transaction_refunds.each {|t| amt += t.amount;}

      amt.should == 1400.0
      transaction_refunds.count.should == 3


    end

  end  # END REFUNDING ORDER FOR ORG

end

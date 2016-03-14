require 'spec_helper'

describe KyckRegistrar::Actions::MakePayment do

  describe "#new" do
    it "takes a requestor" do
      expect{described_class.new}.to raise_error ArgumentError
    end

    it "takes an order" do
      expect{described_class.new(User.new)}.to raise_error ArgumentError
    end
  end

  describe "#execute" do

    let(:requestor) { regular_user }
    let(:org) { create_club }
    let(:sb) { create_sanctioning_body_with_merchant_acct }
    let(:sr) { create_sanctioning_request(org, sb, requestor, {staus: :new}) }
    let(:srp) {
      attrs = {:kind => 'competition', :amount=>1000.0, :sanctioning_body_id => sb.kyck_id}
      req = SanctioningRequestProduct.build(attrs)
      SanctioningRequestProductRepository.persist req
    }


    let(:payment_account){
      @pa = PaymentAccount.build(:obj_id=>org.kyck_id, :obj_type=>org.class.to_s, :balance => 0)
      PaymentAccountRepository.persist @pa
    }

    let(:card_input) {
      input = {description: 'my personal card', address: "123 blah", city: "CLT", state: 'NC', zipcode: "28203", card: {:name => 'Billy Bob', number:'4111111111111111', security_code:'123', kind: :visa, expiration:{month:6, year:2090}} }
      input
    }

    let(:charge_card) {
      c = Object.new
      c.stub(:sale).and_return(@result)
      c.stub(:update).and_return(@result)
      c
    }

    let(:credit_card) {
      c = double()
      c.stub(:last_4){ "4242" }
      c.stub(:token){ "cxvb4" }
      c
    }

    let(:customer) {
      c = double()
      c.stub(:id) { requestor.kyck_id }
      c.stub(:credit_cards){ [credit_card] }
      c
    }

    before(:each) do

      transaction = double()
      transaction.stub(:id) { "1234transaction" }
      transaction.stub_chain(:credit_card_details, :last_4).and_return("4242")

      @result = double()
      @result.stub(:success?).and_return(true)
      @result.stub(:customer).and_return(customer)
      @result.stub(:transaction).and_return(transaction)
    end

    context 'as a user paying for an organization request sanction' do

      let(:order) {
        attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', amount: 1000.0, status: :new, payment_status: :not_sent}
        order = Order.build(attrs)
        OrderRepository.persist! order
      }

      let(:paid_order) {
        attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'sanctioning_request', status: :submitted, amount: 1000.0, payment_status: :authorized}
        order = Order.build(attrs)
        OrderRepository.persist! order
      }

      before(:each) do

        payment_account

        oi = order.add_order_item(:product_for_obj_id=> sr.kyck_id, :product_for_obj_type=> sr.class.to_s, :amount=>srp.amount, :product_id => srp.id, :product_type =>srp.class.to_s, :description => 'Sanctioning Request')
        OrderRepository.persist! order

        sr.order_id = order.id
        SanctioningRequestRepository.persist sr

      end

      context 'with permission to manage organization money' do

        before(:each) do
          add_user_to_obj(requestor, org, {permission_sets:[PermissionSet::MANAGE_REQUEST]})
        end

        context 'should create a new account transaction charging existing customer' do
          let(:input) {{payment_method: @payment_method.id } }

          before(:each) do
            @payment_method = PaymentMethod.build(:user_id=>requestor.kyck_id, :description=>"test", :name=>"BILLY BOB", :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", :last4=>customer.credit_cards[0].last_4, :customer_id=>customer.id, :card_token=>'cxvbg', :kind => :visa)
            PaymentMethodRepository.persist @payment_method

            @action = described_class.new requestor, order
            @action.charge_method = charge_card

          end

          it 'should update order status to submitted' do
            @result = @action.execute input
            order.status.should == :submitted
          end

          it 'should update payment account balance to 1000' do
            @result = @action.execute input
            pa = PaymentAccountRepository.find(@result.payment_account_id)
            pa.balance.to_f.should == 1000.0
          end

          it 'broadcasts the event' do
            listener = double('listener')
            listener.should_receive(:sanctioning_request_deposit_made).with order
            @action.subscribe(listener)
            @result = @action.execute input

          end
        end

        it 'should create a new account transaction charging card' do
          action = described_class.new requestor, order
          action.charge_method = charge_card
          input = input = {description: 'my personal card', address: "123 blah", city: "CLT", state: 'NC', zipcode: "28203", card: {:name => 'Billy Bob', number:'4111111111111111', security_code:'123', expiration:{month:6, year:2090}} }
          result = action.execute input

          order.status.should == :submitted
          pa = PaymentAccountRepository.find(result.payment_account_id)
          pa.balance.to_f.should == 1000.0

        end

        it 'should raise error when order is already paid' do
          action = described_class.new requestor, paid_order
          action.charge_method = charge_card
          input = {stripe_token: @token }
          listener = double('listener')
          listener.should_receive(:payment_error).with an_instance_of(KyckRegistrar::OrderAlreadyPaidError)
          action.subscribe(listener)
          action.execute input
        end

        it 'should raise permission error to use payment method' do
          u = regular_user()
          @payment_method = PaymentMethod.build(:user_id=>(u.kyck_id), :description=>"test", :name=>"BILLY BOB", :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", :last4=>customer.credit_cards[0].last_4, :customer_id=>customer.id, :card_token=>'cxvbg', :kind => :visa)
          PaymentMethodRepository.persist @payment_method

          action = described_class.new requestor, order
          action.charge_method = charge_card
          input = {payment_method: @payment_method.id }
          listener = double('listener')
          listener.should_receive(:payment_error).with an_instance_of(KyckRegistrar::PermissionsError)
          action.subscribe(listener)
          action.execute input
        end

      end
    end

    context 'as a user making a deposit for an organization' do
      let(:order) do
        attrs = {
          initiator_id: requestor.kyck_id,
          payer_id: org.kyck_id,
          payer_type: org.class.to_s,
          payee_id: sb.kyck_id,
          payee_type: sb.class.to_s,
          kind: :deposit,
          amount: 500.0,
          status: :new,
          payment_status: :not_sent
        }
        order = Order.build(attrs)
        OrderRepository.persist order
      end

      before(:each) do
        add_user_to_obj(requestor, org, {permission_sets:[PermissionSet::MANAGE_MONEY, PermissionSet::MANAGE_MONEY]})
        payment_account
      end

      it 'creates a new account transaction charging existing customer' do
        @payment_method = PaymentMethod.build(:user_id=>requestor.kyck_id.to_s, :description=>"test", :name=>"BILLY BOB", :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", :last4=>customer.credit_cards[0].last_4, :customer_id=>customer.id, :card_token=>'cxvbg', :kind => :visa)
        PaymentMethodRepository.persist @payment_method

        action = described_class.new requestor, order
        action.charge_method = charge_card
        input = {payment_method: @payment_method.id }
        result = action.execute input

        result.last4.should == "4242"
        order.status.should == :submitted
        pa = PaymentAccountRepository.find(result.payment_account_id)
        pa.balance.to_f.should == order.amount

      end

      it 'should create a new account transaction charging card' do
        action = described_class.new requestor, order
        action.charge_method = charge_card
        result = action.execute card_input

        result.last4.should == "4242"
        order.status.should == :submitted
        pa = PaymentAccountRepository.find(result.payment_account_id)
        pa.balance.to_f.should == order.amount
      end

      it 'should raise permission error to make a deposit for this organization' do
        user = regular_user

        action = KyckRegistrar::Actions::MakePayment.new user, order
        action.charge_method = charge_card

        listener = double('listener')
        listener.should_receive(:payment_error).with an_instance_of(KyckRegistrar::PermissionsError)
        action.subscribe(listener)
        action.execute(card_input)
      end

      context "when the user wants to save the card" do
        before do
        end
        it "saves the card" do
          cust_method = double
          cust_method.stub(:find) { PaymentMethod.new }
          ccresult = double()
          ccresult.stub(:success?).and_return(true)
          ccresult.stub(:customer_id).and_return("12234")
          ccresult.stub_chain(:credit_card, :token).and_return("1235")
          @cc_method = double
          @cc_method.stub(:create).with(any_args) { ccresult }

          @result.stub_chain(:transaction, :credit_card_details, :token) { "2345" }
          @result.stub_chain(:transaction, :customer_details, :id) { "2345" }

          action = KyckRegistrar::Actions::MakePayment.new requestor, order
          action.charge_method = charge_card
          action.customer_method = cust_method
          action.credit_card_method = @cc_method
          card_input[:card][:make_default] = true

          expect {
            action.execute(card_input.with_indifferent_access)
          }.to(
            change { PaymentMethodData.count }.by(1)
          )
        end
      end
    end

    context 'as a user buying cards for an organization with a 0 balance' do

      let(:order) {
        order = Order.build({initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request', amount: 500.0, status: :new, payment_status: :not_sent})
        OrderRepository.persist order
      }

      let(:payment_method) {
        @payment_method = PaymentMethod.build(:user_id=>requestor.kyck_id, :description=>"test", :name=>"BILLY BOB", :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", :last4=>customer.credit_cards[0].last_4, :customer_id=>customer.id, :card_token=>'cxvbg', :kind => :visa)
        PaymentMethodRepository.persist @payment_method

      }

      before(:each) do
        add_user_to_obj(requestor, org, {permission_sets:[PermissionSet::MANAGE_CARD]})
        order.add_order_item({amount: 500})
        payment_account
      end


      it 'should create a new account transaction charging existing customer and making account balance 0' do
        action = described_class.new requestor, order
        action.charge_method = charge_card
        input = {payment_method: payment_method.id }
        result = action.execute input

        result.last4.should == "4242"
        result.amount.should == 500.0
        order.status.should == :submitted
        pa = PaymentAccountRepository.find(result.payment_account_id)
        pa.balance.to_f.should == 0.0

      end

      it 'should create a new account transaction charging card' do

        action = described_class.new requestor, order
        action.charge_method = charge_card
        result = action.execute card_input

        result.last4.should == "4242"
        result.amount.should == 500.0
        order.status.should == :submitted
        pa = PaymentAccountRepository.find(result.payment_account_id)
        pa.balance.to_f.should == 0.0

      end

      it 'should raise permission error to make a deposit for this organization' do
        action = described_class.new regular_user, order
        listener = double('listener')
        listener.should_receive(:payment_error)
        action.subscribe(listener)
        action.execute card_input
      end

      context "when the order items amount don't match order amount" do

        before do
          order.amount += 100
          order._data.save!
        end
        it "raises an error" do
          action = described_class.new regular_user, order
          listener = double('listener')
          listener.should_receive(:payment_error).with an_instance_of(KyckRegistrar::OrderInvalidError)
          action.subscribe(listener)
          action.execute card_input

        end

      end
    end

    context 'as a user buying cards for an organization with a balance' do
      let(:order) {
        order = Order.build({initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request', amount: 500.0, payment_status: :not_sent})
        OrderRepository.persist order
      }

      before(:each) do
        add_user_to_obj(requestor, org, {permission_sets:[PermissionSet::REQUEST_CARD]})
        @payment_account = PaymentAccount.build(:obj_id=>org.kyck_id, :obj_type=>org.class.to_s, :balance => 500)
        PaymentAccountRepository.persist @payment_account

        @payment_method = PaymentMethod.build(:user_id=>requestor.kyck_id, :description=>"test", :name=>"BILLY BOB", :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", :last4=>customer.credit_cards[0].last_4, :customer_id=>customer.id, :card_token=>'cxvbg', :kind => 'visa')
        PaymentMethodRepository.persist @payment_method
        order.add_order_item({amount: 500})
      end

      it 'should create a new account transaction charging existing customer' do

        order = Order.build({initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request', amount: 400.0, status: :new})
        OrderRepository.persist order

        order.add_order_item({amount: 400})
        action = described_class.new requestor, order
        action.charge_method = charge_card
        input = {payment_method: @payment_method.id }
        result = action.execute input

        result.last4.should == nil
        result.amount.should == 400.0
        result.transaction_type.should == "debit"
        result.kind.should == "liability"
        order.status.should == :submitted
        pa = PaymentAccountRepository.find(result.payment_account_id)
        pa.balance.to_f.should == 100.0

      end

      it "marks the order payment_status as authorized" do

      end

      it 'should create 2 new account transaction charging existing customer' do

        order = Order.build({initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request', amount: 600.0, status: :new})
        OrderRepository.persist order
        order.add_order_item({amount: 600})

        assert_difference 'AccountTransactionRepository.all.count', 2 do
          action = described_class.new requestor, order
          action.charge_method = charge_card
          input = {payment_method: @payment_method.id }
          result = action.execute input

          result.last4.should == "4242"
          result.amount.should == 100.0
          result.transaction_type.should == "credit"
          result.kind.should == "revenue"
          order.status.should == :submitted
          pa = PaymentAccountRepository.find(result.payment_account_id)
          pa.balance.to_f.should == 0.0
        end
      end

      context "when the payment account balance is specifed as the payment method" do

        context "and it has a high enough balance to cover it" do

          before do
            payment_account.balance = 2 * order.amount
            @original_balance = payment_account.balance
            PaymentAccountRepository.persist! payment_account
          end

          it "deducts the amount" do
            action = described_class.new requestor, order
            action.execute(payment_method: 'balance')
            pa = PaymentAccountRepository.find(payment_account.id)
            pa.balance.to_f.should == @original_balance - order.amount

          end

          it "marks the order as submitted" do
            action = described_class.new requestor, order
            action.execute(payment_method: 'balance')
            order.status.should == :submitted

          end
        end

      end
    end

  end
end

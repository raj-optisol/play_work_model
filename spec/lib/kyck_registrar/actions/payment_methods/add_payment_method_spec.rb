require 'spec_helper'



describe KyckRegistrar::Actions::AddPaymentMethod do


  before(:each) do
    ud = FactoryGirl.create(:user, permission_sets: [PermissionSet::MANAGE_TEAM])
    @user = UserRepository.find(ud.id)

    @customer_method = Object.new

    credit_card = double()
    credit_card.stub(:last_4){ "4141" }
    credit_card.stub(:token){ "cxvb4" }      
    customer = double()
    customer.stub(:id) { @user.kyck_id }
    customer.stub(:credit_cards){ [credit_card] }
    customer.stub_chain(:active_card, :last4).and_return("1111")

    result = double()
    result.stub(:success?).and_return(true)
    result.stub(:customer).and_return(customer)

    @customer_method.stub(:create).and_return(result)
    @customer_method.stub(:update).and_return(result)

    @token = "tok_1UpanTGIDzbBb3"

  end

  let(:input) {
    {
      description: 'my personal card', 
      address: "123 blah", 
      city: "CLT", 
      state: 'NC', 
      zipcode: "28203", 
      card: {
        name: 'Billy Bob', 
        number:'4111111111111111', 
        kind: 'visa',
        security_code:'123', 
        expiration_month:6,
        expiration_year:2090
      } 
    }.with_indifferent_access
  }

  it 'should create a new payment source for a user ' do

    expect {
      action = KyckRegistrar::Actions::AddPaymentMethod.new @user
      action.customer_method = @customer_method
      result = action.execute input
    }.to change {PaymentMethodRepository.all.count}.by(1)

  end

  it "should have an expiration_month and year" do
    action = KyckRegistrar::Actions::AddPaymentMethod.new @user
    action.customer_method = @customer_method
    result = action.execute input
    result.expiration_month.should == 6
    result.expiration_year.should == 2090

  end


  # it 'should raise an error when using an invalid stripe token' do
  #   
  #   action = KyckRegistrar::Actions::AddPaymentMethod.new @user
  #   action.customer_method = @customer_method
  #   input = {description: 'my personal card', :name => 'Billy Bob', :address => "123 blah", :city => "CLT", :state => 'NC', :zipcode => "28203", stripe_token: '12312asfsdfs23'}
  #   expect{ result = action.execute input}.to raise_error Stripe::StripeError
  #  
  # end   

end

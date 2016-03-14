require 'spec_helper'
require_relative '../../../../app/models/user'
require_relative '../../../../app/models/payment_method'
require_relative '../../../../app/models/account_transaction'
require_relative '../../../../lib/kyck_registrar/actions/credit_payment_account'


describe KyckRegistrar::Actions::CreditPaymentAccount, broken: true do

  # let(:repository){ OrganizationRequestMemoryRepository}
  # let(:org_repository){ OrganizationMemoryRepository}  
  # 
  
  before(:each) do

    @user = admin_user([PermissionSet::MANAGE_MONEY])

  end

  context 'uscs admin refunding organization request' do
     before(:each) do
       
       u = regular_user()
         
       @org = Organization.build({:kind => :club, :name => 'North Meck 1', :status => :active})
       OrganizationRepository.persist(@org)
       
       @payment_account = PaymentAccount.build(:obj_id =>@org.id, :obj_type=>"Organization", :balance=>0)
       PaymentAccountRepository.persist @payment_account
                
     end
  
     it 'should refund entire order and mark order status as refunded' do
       
           action = KyckRegistrar::Actions::CreditPaymentAccount.new @user, @payment_account      
           input = {:amount=>200}
           result = action.execute input

           result.balance.to_f.should == 200   
           result.account_transactions.count.should == 1
     end  
     

  end
  


end

require 'spec_helper'
require_relative '../../../../app/models/user'
require_relative '../../../../app/models/account_transaction'
require_relative '../../../../lib/kyck_registrar/actions/get_organization_transactions'

describe KyckRegistrar::Actions::GetOrganizationTransactions, broken: true do

  before(:each) do

    @org = create_club
    paymentaccount = PaymentAccount.build({:obj_id=>@org.id, :obj_type=>"Organization"})
    PaymentAccountRepository.persist paymentaccount

    create_payment_transaction (paymentaccount.id)
  
    
  end
  
  describe "for a admin user with right to manage organizations" do

    before(:each) do
      @user = admin_user(["ManageOrganization"])      
      
    end

    it 'should return all transactions for organization ' do
      input = {}
      action = KyckRegistrar::Actions::GetOrganizationTransactions.new @user, @org
      results = action.execute input
      results.count.should == 1
    end
  end

  describe "for staff that can manage the org" do
      before(:each) do
        @user = regular_user
  
        @org.add_staff(@user, "Registrar", ['ManageOrganization', 'ManageTeam', 'ManagePlayer', 'ManageStaff', 'ManageRoster'])
        OrganizationRepository.persist(@org)   
  
      end
  
      it 'should return all transactions for organization' do
  
        input = {}
        action = KyckRegistrar::Actions::GetOrganizationTransactions.new @user, @org
        results = action.execute input
        results.count.should == 1
  
      end
  end
  
  it 'should throw error for user that doesnt have permission to manage organization' do
    user = regular_user
    input = {}
    action = KyckRegistrar::Actions::GetOrganizationTransactions.new user, @org
    expect{ result = action.execute input}.to raise_error KyckRegistrar::PermissionsError

  end
  
end

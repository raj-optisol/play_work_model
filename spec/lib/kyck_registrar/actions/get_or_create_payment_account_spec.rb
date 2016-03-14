require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetOrCreatePaymentAccount do

      let(:user) { regular_user }
      let(:org) { create_club }
      
      context 'as a user that that has permission to retrieve the payment account' do
        before(:each) do

          add_user_to_obj(user, org, {permission_sets:[PermissionSet::MANAGE_MONEY]})
          
        end

        it 'should create a payment account for an organization object ' do
        
          action = described_class.new user, org
          result = action.execute {}
        
          result.obj_type.should == "Organization"
          result.obj_id.to_s.should == org.kyck_id.to_s
        
        end

        it 'should create retrieve an existing payment account for an organization object ' do

          pa = PaymentAccount.build(:obj_id=>org.kyck_id, :obj_type=>org.class.to_s, :balance => 0)     
          PaymentAccountRepository.persist pa

          action = described_class.new user, org
          result = action.execute {}
          PaymentAccountRepository.all.count.should == 1


        end        
      end
      
      
      context 'as a user that that does not have permission to retrieve the payment account' do

        it 'should create retrieve an existing payment account for an organization object ' do

          action = described_class.new user, org
          expect{ described_class.new(user, org).execute()}.to raise_error KyckRegistrar::PermissionsError

        end        
      end

    end
  end
end

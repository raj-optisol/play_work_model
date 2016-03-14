require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateCardProduct do
  
      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a sanctioning body" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end
      
      let(:sb) { create_sanctioning_body }
      
      context 'when requestor has permission' do

        it 'should create a new card product for sb' do
              requestor = add_user_to_obj(regular_user, sb, {title:"USCS", permission_sets:[PermissionSet::MANAGE_MONEY]})          
              input = {"name" => "U12 & Below", "card_type" => "player", "age"=>12, "amount"=>18.0 }
              result = described_class.new(requestor, sb).execute(input)
              result.amount.should == 18.0 
              result.sanctioning_body_id.to_s.should == sb.kyck_id.to_s  
        end
      
        it 'should create a new sanctioning request product for the academy' do
              admin = admin_user
              action = described_class.new(admin, sb)
              input = {"name" => "U10 & Below", "card_type" => "player", "age"=>10, "amount"=>10.0 }
              result = action.execute(input)              
        
              result.amount.should == 10.0               
        end   
        
        it 'should create a new card product for an sb with organization' do
          admin = admin_user
          org = create_club
          action = described_class.new(admin, sb)
          input = {"name" => "U10 & Below", "card_type" => "player", "age"=>10,  "amount"=>10.0, "organization_id"=>org.kyck_id }
          result = action.execute(input)
          result.organization_id.to_s.should == org.kyck_id.to_s
        end
        
      end
      context 'when requestor doesnt have permission' do
      
        it 'should raise a permission error' do
              user = regular_user()        
            input = {"name" => "U14 & Below", "card_type" =>"player", "age" => 14, "amount"=>16.0 }
              expect{ described_class.new(user, sb).execute(input)}.to raise_error KyckRegistrar::PermissionsError
            
        end   
      end

   end
 end
end

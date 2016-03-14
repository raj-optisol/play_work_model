# require 'spec_helper'
# require_relative '../../../../app/models/user'
# require_relative '../../../../app/models/order'
# # require_relative '../../../../app/models/organization_request_deposit'
# # require_relative '../repositories/organization_memory_repository'
# require_relative '../../../../lib/kyck_registrar/actions/get_product'
# 
# 
# describe KyckRegistrar::Actions::GetProduct, broken: true do
# 
#   
#   context 'when retrieving player cards' do
#      before(:each) do
#         ud = FactoryGirl.create(:user, permission_sets: [])
#         @requestor = UserRepository.find(ud.id)
#     
#         user = regular_user()
#         
#         @org = create_club
#         @org.add_staff(@requestor, "Coach", [PermissionSet::REQUEST_PLAYER_CARD])
#         @player = @org.add_player(user, {:gender=>"male", :birthdate=>Date.new(2000,1,2)})        
#         OrganizationRepository.persist @org    
#         
#         @product = CardProduct.build(:age=>16, :gender=>"male", :card_type=>"player", :amount=>18.0)
#         CardProductRepository.persist @product
#         
#       end
#     # 
#      it 'should  return the default product for the player' do
#        action = KyckRegistrar::Actions::GetProduct.new @requestor, @org, @player
# 
#        input = {:obj_id => @player.id, :obj_type => "Player" }
#        result = action.execute input   
#        result.amount.should == 18                       
#      end
# 
#      it 'should return the organization product for the player' do
# 
#        @product2 = CardProduct.build(:age=>16, :card_type=>"player", :amount=>16.0, :obj_id=>@org.id, :obj_type=>@org.class.to_s)
#        CardProductRepository.persist @product2
# 
#        action = KyckRegistrar::Actions::GetProduct.new @requestor, @org, @player
#        input = {:obj_id => @player.id, :obj_type => "Player" }
#        result = action.execute input   
#        result.amount.should == 16           
# 
#      end      
# 
#   end  
# 
# end

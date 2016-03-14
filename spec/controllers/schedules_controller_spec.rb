# require 'spec_helper'
# 
# describe SchedulesController do
#   include Devise::TestHelpers
#   before(:each) do
#     @org = create_club
#     @season = @org.create_season({name:"SEASON One"})
#     OrganizationRepository::SeasonRepository.persist @season
#         
#     @account = FactoryGirl.create(:account)
#     @user = regular_user({kyck_id: @account.kyck_id.to_s})
#     sign_in(@account)
#   end
# 
#   describe "#index" do
# 
#     before(:each) do
#       @team1 = create_team_for_season(@season)
#       @team2 = create_team_for_season(@season)
#       @team3 = FactoryGirl.create(:team)
#     end
# 
#     it "returns the teams for the season" do
#       get :index, season_id: @season.id, format: :json
#       ids = json.each.map {|t| t["id"]} 
#       ids.should include(@team1.id.to_s)
#       ids.should include(@team2.id.to_s)
#     end
# 
#     context "when a name filter is supplied" do
# 
#       it "should filter the teams by that value" do
#         get :index, season_id: @season.id, filter: {name_like: @team2.name}.to_json, format: :json
#         json.count.should == 1
#         
#         json[0]["id"].should == @team2.id.to_s
#       end    
# 
#     end
#   end
# 
#   describe "#create" do
#     context "when the logged in user has manage team rights" do
#       before(:each)  do
#         @org.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_TEAM]})
#         OrganizationRepository.persist @org
#       end
# 
#       let(:team_attributes) {
#         {name: "New Team", gender: "F", age_group: "U12"} 
#       }
# 
#       subject { post :create, season_id: @season.id, team: team_attributes }
# 
#       it "should create a new team" do
# 
#         expect{ 
#           subject
#           @season = OrganizationRepository::SeasonRepository.find(@season.id)
#         }.to change{@season.teams.count}.by(1)
# 
#       end
# 
#       it "should redirect to the organization teams page" do
#         subject
#         response.should redirect_to season_teams_path(@season)
#       end
# 
#     end
#   end
# 
#   describe "#edit" do
#     context "when the logged in user has manage team rights" do
#       before(:each)  do
#         @season.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_TEAM]})      
#         @team = create_team        
#         @season.add_team(@team)
#         OrganizationRepository::TeamRepository.persist @team
# 
#       end
# 
#       it "should assign the team" do
#         get :edit, season_id: @season.id.to_s, id: @team.id.to_s
#         expect(assigns(:team)).to_not  be_nil
#       end
#     end
#     
#      context "when the logged in user does not have manage team rights" do
#         before(:each)  do
#           @team = create_team   
#           @team.add_staff(@user, {title:"Manager"})               
#           @season.add_team(@team)
#           OrganizationRepository::TeamRepository.persist @team
# 
#         end
# 
#         it "should redirect to the season teams page" do
#           get :edit, season_id: @season.id.to_s, id: @team.id.to_s
#           response.should redirect_to season_teams_path(@season) 
#         end
#       end
#       
#   end
# 
#   describe "#update" do
#     let(:new_team_attributes) {
#       {"name" => 'Changed Name', "gender" => 'M', "age_group" => 'U14' } 
#     }
#     
#     context "when the logged in user has manage team rights" do
# 
# 
#       before(:each)  do
# 
#         @season.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_TEAM]})      
#         @team = create_team
#         @season.add_team(@team)
#         OrganizationRepository::TeamRepository.persist @team
# 
#         @mock = double
#         KyckRegistrar::Actions::UpdateTeam.stub!(:new) { @mock }
#       end
# 
# 
#       it "should call the update team action" do
#         @mock.should_receive(:execute).with(new_team_attributes)
#         put :update, season_id: @season.id, id: @team.id.to_s, team: new_team_attributes
#       end
# 
#       it "should redirect to the season's team page" do
#         @mock.stub(:execute).with(any_args())
#         put :update, season_id: @season.id.to_s, id: @team.id.to_s, team: new_team_attributes
#         response.should redirect_to season_teams_path(@season) 
#       end
#     end
#     
#     context "when the logged in user does NOT have manage team rights" do
#        before(:each)  do
#          @team = create_team   
#          @team.add_staff(@user, {title:"Manager"})               
#          @season.add_team(@team)
#          OrganizationRepository::TeamRepository.persist @team
#          
#          @mock = double
#          KyckRegistrar::Actions::UpdateTeam.stub!(:new) { @mock }
# 
#        end
# 
#        it "should redirect to the season teams page" do
#          @mock.should_receive(:execute).with(new_team_attributes)
#          put :update, season_id: @season.id.to_s, id: @team.id.to_s, team: new_team_attributes
#          response.should redirect_to season_teams_path(@season) 
#        end
#      end
#      
#   end
#   
#   describe "#destroy" do
#     context "when the logged in user has manage team rights" do
#       before(:each)  do
#         @season.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_TEAM]})      
#         @team = create_team
#         @season.add_team(@team)
#         OrganizationRepository::SeasonRepository.persist @season
# 
#         @mock = double
#         KyckRegistrar::Actions::DeleteTeam.stub!(:new) { @mock }
#       end
#         
#       it "should call the delete action" do
#         @mock.should_receive(:execute).with()
#         delete :destroy, season_id: @season.id, id: @team.id.to_s
#       end
# 
#       it "should redirect to the organization's team page" do
#         @mock.stub(:execute).with(any_args())
#         delete :destroy, season_id: @season.id, id: @team.id.to_s
#         response.should redirect_to season_teams_path(@season) 
#       end
# 
#       context "json"  do
#         it "should respond right" do
#           @mock.stub(:execute).with(any_args())
#           delete :destroy, season_id: @season.id.to_s, id: @team.id.to_s, format: :json
#           response.status.should == 204
#         end
# 
#       end
#     end
#   end
# end

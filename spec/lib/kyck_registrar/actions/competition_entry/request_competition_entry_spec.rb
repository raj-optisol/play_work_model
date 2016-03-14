require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RequestCompetitionEntry do


      let(:club) {
        create_club
      }
      let(:requestor) {regular_user }
  
      let(:team) {create_team}
      let(:roster) { create_roster_for_team(team) }

      let(:competition) { create_competition }
      let(:division) { create_division_for_competition(competition) }


      before(:each) do
        add_user_to_org(requestor, team, {title: "registrar", permission_sets: [PermissionSet::MANAGE_REQUEST]}, UserRepository)    
      end


      it 'creates a competition entry with status pending' do

        action = described_class.new requestor, team, competition
        result = action.execute({roster_id:roster.kyck_id, division_id: division.kyck_id})
        # 
        # roster._data.reload
        # roster.competition_entry.competition.id.should == competition.id

        entry = CompetitionEntryRepository.find(result.id)      
        entry.issuer.id.should_not be_nil
        entry.competition.id.should == competition.id    
        entry.division.id.should == division.id    
        entry.team.id.should == team.id    
        entry.roster.id.should == roster.id                      
        entry.status.should == :pending

      end
      # 
      # it "defaults to club" do
      #   action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #   result = action.execute sr_params
      #   result.kind.should == :club
      # end
      # 
      # it "captures the payload" do
      #   action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #   result = action.execute sr_params
      #   json = JSON.parse(result.payload)
      #   json["number_of_players_male_U11"].should == 20
      # end
      # 
      # it "publishes a request created event" do
      #   academy = create_academy()
      #   action = KyckRegistrar::Actions::RequestSanction.new requestor, academy, sanctioning_body
      #   listener = double('listener')
      #   listener.should_receive(:sanctioning_request_created).with(instance_of(SanctioningRequest), instance_of(Organization), instance_of(SanctioningBody))
      #   action.subscribe(listener)
      #   action.execute(sr_params)
      # 
      # end
      # 
      # it "sets the org to on_behalf_of" do
      #   action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #   result = action.execute sr_params
      #   result.on_behalf_of.kyck_id.should == club.kyck_id  
      # end
      # 
      # context "when contacts to existing users are provided" do
      #   let(:doc) {regular_user}
      #   let(:input) {
      #     sr_params[:doc] = {title: 'doc', user_id: doc.kyck_id }
      #     sr_params
      #   }
      # 
      #   it "calls add staff" do
      #     mock_execute_action(KyckRegistrar::Actions::AddStaff, {"user_id"=> doc.kyck_id, "title"=> 'doc'})
      # 
      #     action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #     action.execute(input)
      #   end
      # 
      #   context "when the provided attributes are invalid" do
      #     let(:input) {
      #       sr_params[:doc] = {title: 'doc', user_id: "" }
      #       sr_params[:president] = {title: 'president', user_id: "" }
      #       sr_params
      #     }
      #     it "does not" do
      #       should_not_execute_action(KyckRegistrar::Actions::AddStaff, {"user_id"=> "", "title"=> 'doc'})
      #   
      #       action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #       action.execute(input)
      #       
      #     end
      #   end
      # 
      # end
      # 
      # context "when contacts to new users are provided" do
      #   let(:input) {
      #     sr_params[:doc] = {"title"=> 'doc', "first_name"=> 'Barney', "last_name"=> 'Rubble', "email"=>'barney@rubble.com', "phone_number"=> '777-777-8888' }
      #     sr_params[:president] = {"title"=> 'president', "first_name"=> 'Billy', "last_name"=> 'Bob', "email"=>'billy@bob.com', "phone_number"=> '777-777-9999' }      
      #     sr_params
      #   }
      # 
      #   it "calls add staff" do
      #     # mock_execute_action(KyckRegistrar::Actions::AddStaff, input[:doc])
      #     orgid = requestor.staff_for[0].id
      #     action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      #     sr = action.execute(input)
      #     o = OrganizationRepository.find(orgid)
      #     o.staff.count.should == 3
      # 
      #   end
      # end
      # 
      # context "when a sanctioning request already exists" do
      # 
      #   let!(:sanctioning_request) { create_sanctioning_request(sanctioning_body, club, requestor)}
      #   subject{described_class.new(requestor, club, sanctioning_body)}
      # 
      #   it "returns that request" do
      #     request = subject.execute({players: {u12: {boys: 20, girls: 20}}}) 
      #     request.id.should == sanctioning_request.id
      #   end  
      # end

    end
  end
end

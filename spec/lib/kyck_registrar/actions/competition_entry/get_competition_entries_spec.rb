require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetCompetitionEntries do

        let(:club) {
          create_club
        }
        let(:season) {create_season_for_organization(club)}
        let(:requestor) {regular_user }
        let(:admin_requestor) { admin_user}  
    
        let(:team) {create_team}
        let(:roster) { create_roster_for_team(team) }
  
        let(:team2) {create_team}
        let(:roster2) { create_roster_for_team(team2) }
        let(:roster3) { create_roster_for_team(team2) }        

        let(:competition) { create_competition }
        let(:division) { create_division_for_competition(competition) }
        let(:division2) { create_division_for_competition(competition) }

        before(:each) do

          # add_user_to_obj(requestor, team2, {title: "registrar", permission_sets: [PermissionSet::MANAGE_REQUEST]})
        end

        describe "#initialize" do
          it "takes a requestor and a team" do
            expect{described_class.new(requestor, team)}.to_not raise_error  
          end
        end

        describe "#execute" do


          let(:request1) { create_competition_entry(requestor, competition, division, team, roster ) }

          let(:request2) { create_competition_entry(admin_requestor, competition, division, team2, roster2, {status:  'approved' }) }
          let(:request3) { create_competition_entry(requestor, competition, division2, team2, roster3) }          

          before(:each) do
            @request1 = request1
            @request2 = request2
            @request3 = request3            
          end

          context "for a division" do
            subject {described_class.new requestor, competition}

            context 'as staff with permission' do

              before(:each) do
                s = competition.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_REQUEST]})
                UserRepository.persist requestor
              end

              it 'returns all competition requests' do
                input = {}
              
                result = subject.execute input
                result.count.should == 3
              
              end

              context "when conditions are supplied" do
                it 'returns pending requests ' do
                  input = {:conditions => {:status => 'pending' }}
                  result = subject.execute input
                  result.count.should == 2
                end
                
                it 'returns pending requests for a division ' do
                  input = {:conditions => {:status => 'pending' }, :division_conditions => {:kyck_id => division2.kyck_id }}
                  result = subject.execute input
                  result.count.should == 1                  
                  result.first.division.id.should == division2.id

                end
                                
              end

            end  # end context with permission
            
            context 'as a user with no permission' do
                    
              it 'should raise an error' do      
                expect{subject.execute({})}.to raise_error PermissionsError
              end
            end      

            context "for a sanctioned competition" do

              let(:uscs) {create_sanctioning_body }

              before do
                create_sanction_for_sb_and_item(uscs, competition)
                add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_ORGANIZATION])
              end

              context "when the current user is a sanctioning body admin" do

                it 'returns all competition requests' do
                  input = {}
                  result = subject.execute input
                  result.count.should == 3
                
                end
              end
            end
      
          end # end context for a division

          context "for a team" do
            subject {described_class.new requestor, team2}
          
            context 'as staff with permission' do
          
              before(:each) do
                add_user_to_obj(requestor, team2, {title: "coach", permission_sets: [PermissionSet::MANAGE_REQUEST]})
              end
          
              it 'returns all team requests' do
                input = {}
                result = subject.execute input
                result.count.should == 2
          
              end
          
              context "when conditions are supplied" do
                it 'returns requests based on conditions ' do
                  input = {:conditions => {:status => 'pending' }}
                  result = subject.execute input
                  result.count.should == 1
                end        
                
                it 'returns requests based on roster ' do
                  input = {:roster_conditions => {:kyck_id => roster2.kyck_id }}
                  result = subject.execute input
                  result.count.should == 1
                end                
              end
          
            end  # end context for a team as staff with permission
            
            context 'as a user with no permission' do
                    
              it 'should raise an error' do      
                expect{subject.execute({})}.to raise_error PermissionsError
                
              end
            end      
                
          end # end context for a team

        end # end EXECUTE

    end
  end
end

require_relative '../../../../lib/kyck_registrar/actions/create_registration'

module KyckRegistrar
  module Actions
    describe CreateRegistration, broken: true do
      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a season" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        before(:each) do
          @requestor = regular_user  
          @org = create_club
          @season = Season.build(name: "The Season", start_date:DateTime.now, end_date:(DateTime.now+6.months))
          @org.add_season(@season)
          OrganizationRepository.persist @org

          # @team = Team.build(name: 'New Team')
          # @season.add_team(@team)
          # OrganizationRepository::SeasonRepository.persist @season
                  
        end
        
        context "user has permission" do
            before(:each) do
                @org.add_staff(@requestor, {permission_sets:[PermissionSet::MANAGE_SEASON]})
                OrganizationRepository.persist @org                
            end
            it "should create a new registration" do
                  result = described_class.new(@requestor, @season).execute({name:"registration one", start_date:DateTime.now.strftime("%m/%d/%Y"), end_date:(DateTime.now+6.months).strftime("%m/%d/%Y"), cost:20.0})
                  
                  @season.registrations.count.should == 1
            end
        
            it "should raise invalide attributes error" do
                expect { described_class.new(@requestor, @season).execute({name:"another registration"}) }.to raise_error InvalidAttributesError              
            end

        end
        
        context "user does not have permission" do
          it "should raise permission error" do
              expect { described_class.new(@requestor, @season).execute({name:"another registration", start_date:DateTime.now.strftime("%m/%d/%Y"), end_date:(DateTime.now+6.months).strftime("%m/%d/%Y")}) }.to raise_error PermissionsError              
          end
        end
                        
      end
    end
  end
end

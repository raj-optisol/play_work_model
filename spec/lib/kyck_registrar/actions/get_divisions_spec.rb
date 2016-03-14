require_relative '../../../../lib/kyck_registrar/actions/get_divisions'
module KyckRegistrar
  module Actions
    describe GetDivisions do

      subject{KyckRegistrar::Actions::GetDivisions} 

      it "requires a requestor" do
        expect{subject.new}.to raise_error ArgumentError
      end


      describe "#execute" do

        let(:season) {create_season_for_organization(org)}
        let(:comp) { create_competition}
        let!(:div1) {create_division_for_competition(comp)}
        let(:requestor) {regular_user}

        context "for competition" do
          describe "when the requestor has the required permisson" do
            before(:each) do
              comp.add_staff(requestor, {title:"Coach", permission_sets:[PermissionSet::MANAGE_COMPETITION]})

              CompetitionRepository.persist comp
            end

            it "returns the divisions for the competition" do
              action = subject.new(requestor, comp)
              divs = action.execute
              divs.count.should == 1
              divs.first.id.should == div1.id
            end

            describe "when search parameters are supplied" do
              let(:div2) {create_division_for_competition(comp)}

              it "should filter the results" do
                action = subject.new(requestor, comp)
                seas = action.execute({conditions:{name_like: div2.name}})
                seas.count.should == 1
                seas.first.id.should == div2.id
              end
            end
          end
        end

        describe "when the requestor is admin" do
          let(:requestor) {admin_user}
          let(:comp2) { create_competition}
          let!(:org2div1) {create_division_for_competition(comp2)}

          it "returns all competitions" do
            action = subject.new(requestor)
            seas = action.execute
            seas.count.should == 2            
          end
        end

        describe "when the requestor is not associated to comp" do
          before(:each) do
            @requestor = regular_user  
          end

          it "should raise permission error" do
            action = subject.new(@requestor)              
            expect{action.execute }.to raise_error PermissionsError
          end                      
        end        

      end

    end
  end
end

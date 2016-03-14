require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetCardProducts do

      subject{KyckRegistrar::Actions::GetCardProducts} 
      let(:uscs) { create_sanctioning_body(name: 'USCS')}
      let(:card_product) {create_card_product(uscs)}
      let(:card_product2) {create_card_product(uscs)}
      let(:requestor) { regular_user}

      it "requires a requestor" do
        expect{subject.new}.to raise_error ArgumentError
      end


      describe "#execute" do
        describe "when the requestor has the required permisson" do
          before(:each) do
            add_user_to_org(requestor, uscs, {title:"Coach", permission_sets:[PermissionSet::MANAGE_MONEY]})
            card_product
          end

          it "returns the card products" do
            action = subject.new(requestor, uscs)
            cps = action.execute
            cps.count.should == 1
            cps.first.id.should == card_product.id
          end

          describe "when search parameters are supplied" do
            before(:each) do
            end

            it "should filter the results" do
            end
          end

          context "when an organization is supplied" do
            let(:club) {create_club}

            context "and that club has special pricing" do
              let!(:org_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: club.kyck_id )}
              let!(:dup_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 14 )}

              it "returns that club's pricing" do
                  action = subject.new(requestor, uscs, club)
                  cps = action.execute
                  cps.count.should == 2
                  ids  = cps.map(&:id)
                  ids.should include org_cp.id
                  ids.should_not include dup_cp.id
              end
            end
          end

          context "when competition is supplied" do
            let(:comp) {create_competition}

            context "and that competition has special pricing" do
              let!(:comp_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: comp.kyck_id )}

              it "returns that competition's pricing" do
                  action = subject.new(requestor, uscs, comp)
                  cps = action.execute
                  cps.count.should == 2
                  ids  = cps.map(&:id)
                  ids.should include comp_cp.id
              end
            end
          end

          context "when a team is supplied" do
            let(:club) {create_club}
            let(:team) {create_team_for_organization(club)}

            context "and that team's club has special pricing" do

              let!(:org_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: club.kyck_id )}
              it "returns the card products for that team's club" do
                action = subject.new(requestor, uscs, team)
                cps = action.execute
                cps.count.should == 2
                ids  = cps.map(&:id)
                ids.should include org_cp.id
              end
            end

            context "that is part of a competition" do
              let(:comp) {create_competition}
              let(:div) {create_division_for_competition(comp)}

              before do
                create_competition_entry(requestor, comp, div, team, nil, attrs={status: :approved, kind: :request} )
              end

              context "and that competition has special pricing" do
                let!(:comp_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: comp.kyck_id )}
                it "returns the card products for that team's competition" do
                  action = subject.new(requestor, uscs, team)
                  cps = action.execute
                  cps.count.should == 2
                  ids  = cps.map(&:id)
                  ids.should include comp_cp.id
                end
              end
            end
          end   # END TEAM IS SUPPLIED

          context 'when card product has been deleted' do
            before do
              card_product._data.destroy
              card_product2
            end

            it "returns the non deleted card products" do
              action = subject.new(requestor, uscs)
              cps = action.execute
              cps.count.should == 1
              cps.first.id.should == card_product2.id
            end
          end

        end  # END Requestor has permission
      end  # END EXECUTE

    end
  end
end

require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateCardProduct do
      let(:sanctioning_body) { create_sanctioning_body }
      let(:club) { create_club }
      let(:cp) { create_card_product(sanctioning_body) }
      let(:cp_for_org) { create_card_product(sanctioning_body, {organization_id:club.kyck_id } ) }
      let(:requestor) { regular_user }
      subject { described_class.new(requestor, cp, sanctioning_body)}

      describe "#initialize" do
        it "takes a requestor and a sanctioning_body" do
          expect {subject}.to_not raise_error
        end
      end
      
      describe "#execute" do
        context "when the requestor has the right permissions" do
          before(:each) do
            sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_MONEY]})
            UserRepository.persist!(requestor)
          end

          it "updates the card_product" do
            result = subject.execute({amount: 15.0})            
            result.amount.should == 15.0
            
          end
          
          it "updates the card_product by removing the organization" do
            result = described_class.new(requestor, cp_for_org, sanctioning_body).execute({organization_id: '', })            
            result.organization_id.to_s.should == ''            
          end
          
        end

        context "when the requestor does not have the right permissions" do
          it "raises an error" do
            expect { subject.execute({})}.to raise_error PermissionsError
            
          end
        end
      end
    end
  end
end

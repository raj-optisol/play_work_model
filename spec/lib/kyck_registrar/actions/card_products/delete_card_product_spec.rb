require 'spec_helper'

module KyckRegistrar
  module Actions
    describe DeleteCardProduct do
      let(:requestor) {regular_user}
      let(:uscs) {create_sanctioning_body(name: 'USCS')}
      let!(:card_product) {create_card_product(uscs)}

      describe "#execute" do
        subject {described_class.new(requestor, uscs)} 

        context "when the user has permissions" do
          before do
            add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
          end
          
          it "deletes the card product" do
            expect {subject.execute({id: card_product.id})}.to change {CardProductRepository.all.count}.by(-1)
          end
        
        end

        context "when the user does not have permission" do
        
          it "raises an exception" do
            expect {subject.execute({id: card_product.id})}.to raise_error PermissionsError
          end
          
        
        end
      end
    end
  end
end

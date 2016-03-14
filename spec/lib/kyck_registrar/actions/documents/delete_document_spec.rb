require 'spec_helper'

module KyckRegistrar
  module Actions
    describe DeleteDocument do
     
      describe "#execute" do
        
        context "when the user has permission" do
          let(:requestor) {regular_user}
          let(:doc) {create_document_for_user(requestor)}
          subject {described_class.new(requestor, doc)}

          context "and the document is not associated with any cards" do

            it "deletes the document" do
              expect {subject.execute}.to change {
                DocumentRepository.find_by_attrs(kyck_id: doc.kyck_id).count
              }.by(-1)

            end

            it "broadcasts that the document is deleted" do
              listener = double('listener')
              listener.should_receive(:document_deleted).with doc.kyck_id
              subject.subscribe(listener)
              subject.execute()
            end
          end

          context "when the document is associated with a card" do
            let(:club) { create_club}
            let(:uscs) { create_club}
            let(:card) {create_card(requestor, club, uscs)} 

            before do
              card.add_document(doc)
              CardRepository.persist!(card)
            end
           
            it "removes the association between the doc and user" do
              doc.owner.should_not be_nil
              subject.execute
              doc.owner.should be_nil
            end

            it "does not delete the document" do
              DocumentRepository.should_not_receive(:delete)
              subject.execute
            end
          
          end
        
        end
      end
    end
  end
end

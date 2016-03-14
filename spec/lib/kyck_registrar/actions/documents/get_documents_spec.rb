require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetDocuments do
      let(:requestor) { regular_user}
      let!(:document1) {
        d = requestor.create_document({title: "Waiver for Club", kind: :waiver, url:'http://waivers.com/url.pdf'})
        DocumentRepository.persist d
      }
      subject {described_class.new(requestor)}

      describe "#execute" do
        it "returns the documents for the user" do
          results = subject.execute
          results.count.should == 1
        end
      end
    end
  end
end

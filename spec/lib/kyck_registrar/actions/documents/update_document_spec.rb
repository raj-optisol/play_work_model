require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateDocument do
      describe "#execute" do
        let(:requestor) {regular_user}
        let(:doc){ create_document_for_user(requestor)}

        let(:new_attributes) { 
          {
            title: "New Title",
            file_name: 'new_file.pdf'
          }

        }

        subject{described_class.new(requestor, doc)}
        it "changes the doc attributes" do
          result = subject.execute(new_attributes)
          result.title.should == new_attributes[:title]
          result.file_name.should == new_attributes[:file_name]
        end
      end
    end
  end
end

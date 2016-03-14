require 'spec_helper'

describe DocumentListCell do

  context "cell instance" do
    subject { cell(:document_list) }

    it 'should respond to show' do
      # Given the new API which does not set the context to the cell itself
      # but rather to a wrapper with a method_missing definition that
      # delegates to the cell, which is a private instance variable thereof,
      # this is the only way I could reasonably test that the cell does
      # in fact implement the method in question. It will still raise an
      # ArgumentError, but if the method were entirely absent it would
      # raise a NoMethodError, and so we check for the exclusion of that
      # particular exception
      expect { show }.not_to raise_error NoMethodError
    end
  end

  context "cell rendering" do
    let(:requestor) {regular_user}
    context "rendering show" do
      before do
        mock_execute_action(KyckRegistrar::Actions::GetDocuments, nil, [Document.new])
      end
      subject { render_cell(:document_list, :show, requestor: requestor, user: requestor) }

      it { should have_selector("h4", :text => "Documents") }
      it { should have_selector("div.mygrid")}
    end
  end

end

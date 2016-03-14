require 'spec_helper'

describe DocumentsController do
  include Devise::TestHelpers

  let(:requestor) {regular_user}

  before do
    sign_in_user(requestor)
  end

  describe "#create" do

    let(:document_params) {
      { 
        "kind" => 'avatar',
        "url" => 'http://image.com/png'
      } 
    }

    it "calls the right action" do
      mock_execute_action(KyckRegistrar::Actions::CreateDocument, document_params, Document.build)
      post :create, format: :json, user_id: requestor.kyck_id, document: document_params
    end
  end

  describe "#update" do

    let(:document_params) {
      { 
        "title" => 'Changed Doc',
        "last_reviewed_by" => "Some Dood",
        "last_reviewed_on" => DateTime.now.to_i,
      } 
    }
    let(:document) {create_document_for_user(requestor)}

    it "calls the right action" do
      mock_execute_action(KyckRegistrar::Actions::UpdateDocument, document_params, Document.build)
      put :update, format: :json, user_id: requestor.kyck_id, id: document.kyck_id, document: document_params
    end
  end

  describe "#index" do
    it "gets the documents" do
      mock_execute_action(KyckRegistrar::Actions::GetDocuments,nil, [Document.new] )
      get :index, format: :json, user_id: requestor.kyck_id
    end

    context "when the user_id is not the current user" do
      let(:other_user) { regular_user}
      let(:document) {create_document_for_user(other_user)}
      let(:action_stub) {Object.new}

      context "and the user has permissions" do
        before do
          requestor.stub(:admin?) {true} 
        end

        it "gets the documents" do
          KyckRegistrar::Actions::GetDocuments.should_receive(:new) do |arg1, arg2|
            arg1.kyck_id.should == requestor.kyck_id
            arg2.kyck_id.should == other_user.kyck_id
          end.and_return(action_stub )
          action_stub.stub(:execute).and_return([document])
          get :index, format: :json, user_id: other_user.kyck_id
        end
      end

    end
  end
end

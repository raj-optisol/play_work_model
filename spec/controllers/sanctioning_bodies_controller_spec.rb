require 'spec_helper'

describe SanctioningBodiesController, type: :controller do

  let(:sanctioning_body) {create_sanctioning_body }
  let(:user) { regular_user}
  before(:each) do
    sign_in_user(user)
  end

  describe "#edit" do
    context "when the current user is allowed to edit" do

      let(:sb_params){
        {
          conditions: {kyck_id: sanctioning_body.kyck_id},
          permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY] 
        } 
      }

      before(:each) do
        sanctioning_body.add_staff(user, {
          title: 'Admin', 
          permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]
        }) 
      end

      it "calls the get sanctioning body action" do
        action = Object.new
        action.should_receive(:execute).with(sb_params).and_return([sanctioning_body])
        KyckRegistrar::Actions::GetSanctioningBodies.stub(:new) {action}
        get :edit, id: sanctioning_body.kyck_id
      end

    end

  end

  describe "#show" do

    context "when the user is signed in" do
      it "should call get sanctioning body action" do
        action = Object.new
        action.should_receive(:execute).with({conditions: {kyck_id: sanctioning_body.kyck_id}}).and_return([sanctioning_body])
        KyckRegistrar::Actions::GetSanctioningBodies.stub(:new) {action}
        get :show, id: sanctioning_body.kyck_id
      end
    end

  end

  describe "#update" do
    context "when the current user is allowed to edit" do
      let(:sb_parms){ {"name" => 'New Name', "url" =>  'http://newname.info'}}
      before(:each) do
        sanctioning_body.add_staff(user, {
          title: 'Admin', 
          permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]
        }) 
      end

      it "calls the get sanctioning body action" do
        action = Object.new
        action.should_receive(:execute).with(sb_parms).and_return([sanctioning_body])
        KyckRegistrar::Actions::UpdateSanctioningBody.stub(:new) {action}
        put :update, id: sanctioning_body.kyck_id, sanctioning_body: sb_parms 
      end

      it "redirects to the sanctioning body index page" do
        action = Object.new
        action.stub(:execute).with(sb_parms).and_return([sanctioning_body])
        KyckRegistrar::Actions::UpdateSanctioningBody.stub(:new) {action}
        put :update, id: sanctioning_body.kyck_id, sanctioning_body: {name: 'New Name', url: 'http://newname.info'}
        response.should redirect_to sanctioning_body_path(sanctioning_body) 
      end

    end

    context "when the current user is not allowed to edit" do
      it "404s " do
        action = Object.new
        action.stub(:execute).with(any_args).and_raise(KyckRegistrar::PermissionsError)
        KyckRegistrar::Actions::UpdateSanctioningBody.stub(:new) {action}

        put :update, id: sanctioning_body.kyck_id, sanctioning_body: {name: 'Arse'}
        response.status.should == 404
      end
    end
  end

  describe "#index" do
    it "calls the action" do
      action = Object.new
      action.should_receive(:execute).and_return([sanctioning_body])
      KyckRegistrar::Actions::GetSanctioningBodies.stub(:new) {action}
      get :index 
    end
  end
end

require 'spec_helper'

describe DivisionsController do
  include Devise::TestHelpers
  let(:org) {create_club}
  let(:comp) {create_competition}
  let(:requestor) {regular_user}

  before(:each) do
    sign_in_user(requestor)
  end

  describe "#create" do
    context "when a user has rights to manage competitions" do
      before(:each) do
        org.add_staff(requestor, {title:"Registrar", permission_sets:[PermissionSet::MANAGE_COMPETITION]})
        OrganizationRepository.persist! org
      end

      it "should call the create division action" do
        @mock = double
        @mock.should_receive(:execute).with({"name" => "New Division", "age"=>"18", "gender" => "male"})
        KyckRegistrar::Actions::CreateDivision.stub(:new) { @mock }
        post :create, competition_id: comp.kyck_id.to_s, division: {name: "New Division", age:"18", gender:"male"}
      end

      it "should redirect to the team rosters page" do
        @mock = double
        @mock.stub(:execute).with({"name" => "New Division", "age"=>"18", "gender" => "male"})
        KyckRegistrar::Actions::CreateDivision.stub(:new) { @mock }
        post :create, competition_id: comp.kyck_id.to_s, division: {name: "New Division", age:"18", gender:"male"}
        response.should redirect_to competition_divisions_path(comp)
      end
    end
  end

  describe "#index" do
    context "when a user has rights to manage competitions" do
      let(:div) {create_division_for_competition(comp)}
      before(:each) do
        org.add_staff(requestor, {title:"Registrar", permission_sets:[PermissionSet::MANAGE_COMPETITION]})
        OrganizationRepository.persist org
        stub_execute_action(KyckRegistrar::Actions::GetDivisions, nil, [div])
      end


      it "should show the divisions for the competition" do
        get :index, competition_id: comp.kyck_id.to_s, format: :json
        json[0]["id"].should == div.kyck_id
      end
    end
  end

  describe "#destroy" do
    context "when the logged in user has manage competition rights" do
      let(:div) {create_division_for_competition(comp)}
      before(:each) do
        org.add_staff(requestor, {title:"Registrar", permission_sets:[PermissionSet::MANAGE_COMPETITION]})
        OrganizationRepository.persist org

        @mock = double
        KyckRegistrar::Actions::RemoveDivision.stub(:new) { @mock }
      end

      it "should call the delete action" do
        @mock.should_receive(:execute).with()
        delete :destroy, competition_id: comp.kyck_id, id: div.kyck_id.to_s
      end

      it "should redirect to the competition's division page" do
        @mock.stub(:execute).with(any_args())
        delete :destroy, competition_id: comp.kyck_id, id: div.kyck_id.to_s
        response.should redirect_to competition_divisions_path(comp)
      end

      context "json"  do
        it "should respond right" do
          @mock.stub(:execute).with(any_args())
          delete :destroy, competition_id: comp.kyck_id, id: div.kyck_id.to_s, format: :json
          response.status.should == 204
        end
      end

    end
  end

  describe "#show" do
    context "when a user has rights to manage competitions" do
      before(:each) do
        # @org.add_staff(@user, {title:"Registrar", permission_sets:[PermissionSet::MANAGE_COMPETITION]})
        # OrganizationRepository.persist @org
        #
        # @comp = @season.create_competition(name:"comp 1")
        # CompetitionRepository.persist @comp
        #
        # @roster = Roster.build(name:"Roster One")
        # OrganizationRepository::TeamRepository::RosterRepository.persist @roster
        # @comp.add_roster(@roster)
        #
        # CompetitionRepository.persist @comp
        #
        # @mock = double

      end

      context "and json is requested" do
        # it "includes the players" do
        #   get :show, id: @comp.id, format: :json
        #   json["rosters"].count.should == 1
        # end
      end

    end

  end
end

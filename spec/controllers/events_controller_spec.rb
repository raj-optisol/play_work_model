require 'spec_helper'

describe EventsController do
  include Devise::TestHelpers
  before(:each) do
    @team = create_team
    @schedule = create_schedule_for_obj(@team, {name:"master", kind:"master"})
    @ev1 = create_event_for_schedule(@schedule)

    @account = FactoryGirl.create(:account)
    @user = regular_user({kyck_id: @account.kyck_id.to_s})
    sign_in(@account)
  end

  describe "#index" do

    before(:each) do

      # @ev1 = create_event_for_schedule(@schedule)
      @ev2 = create_event_for_schedule(@schedule)
      # @ev3 = create_event_for_schedule(@schedule)
    end

    it "returns the events for the team" do
      get :index, team_id: @team.kyck_id, format: :json, start_with: "team"
      ids = json.each.map {|t| t["id"]}
      ids.should include(@ev1.kyck_id.to_s)
      ids.should include(@ev2.kyck_id.to_s)
    end

  end

  describe "#create" do
    context "when the logged in user has manage schedule rights" do
      before(:each)  do
        @team.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
        OrganizationRepository::TeamRepository.persist @team
          Oriented.graph.commit
      end

      let(:event_attributes) {
        {name:"practice2", start_date:(DateTime.now.utc), end_date:(DateTime.now+2.hours).utc, address1: '123 elm st', city: 'clt', state: 'nc', zipcode: '28105'}.with_indifferent_access
      }

      subject { post :create, team_id: @team.kyck_id, sevent: event_attributes, start_with: "team" }

      it "should create a new event" do

        expect{
          subject
          @schedule = ScheduleRepository.find(@schedule.id)
          Oriented.graph.commit
        }.to change{@schedule.events.count}.by(1)

      end
    end
  end

  describe "#edit" do

    context "when the logged in user has manage schedule rights" do
      before(:each)  do
        @team.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
        OrganizationRepository::TeamRepository.persist @team
      end

      it "should assign the team" do
        get :edit, team_id: @team.kyck_id.to_s, id: @ev1.kyck_id.to_s, start_with: "team"
        expect(assigns(:event)).to_not  be_nil
      end
    end

     context "when the logged in user does not have manage schedules rights" do
        # before(:each)  do
        #   @team = create_team
        #   @team.add_staff(@user, {title:"Manager"})
        #   @season.add_team(@team)
        #   OrganizationRepository::TeamRepository.persist @team
        #
        # end

        it "should redirect to the team events page" do
          get :edit, team_id: @team.kyck_id.to_s, id: @ev1.kyck_id.to_s, start_with: "team"
          response.should redirect_to team_events_path(@team)
        end
      end

  end

  describe "#update" do
    let(:new_event_attributes) {
        {name:"practice2", start_date:(DateTime.now.utc.to_s), end_date:(DateTime.now+2.hours).utc.to_s}
    }

    context "when the logged in user has manage schedules rights" do

      before(:each)  do

        @team.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
        UserRepository.persist @user

        @mock = double
        KyckRegistrar::Actions::UpdateEvent.stub!(:new) { @mock }
      end


      it "should call the update event action" do
        @mock.should_receive(:execute).with(new_event_attributes.stringify_keys!)
        put :update, team_id: @team.kyck_id, id: @ev1.kyck_id.to_s, sevent: new_event_attributes, start_with: "team"
      end

      it "should redirect to the team's events page" do
        @mock.stub(:execute).with(any_args())
        put :update, team_id: @team.kyck_id.to_s, id: @ev1.kyck_id.to_s, sevent: new_event_attributes, start_with: "team"
        response.should redirect_to team_events_path(@team)
      end
    end

    context "when the logged in user does NOT have manage schedule rights" do
       before(:each)  do
         # @team = create_team
         # @team.add_staff(@user, {title:"Manager"})
         # @season.add_team(@team)
         # OrganizationRepository::TeamRepository.persist @team

         @mock = double
         KyckRegistrar::Actions::UpdateEvent.stub!(:new) { @mock }

       end

       it "should redirect to the team events page" do
         @mock.should_receive(:execute).with(new_event_attributes.stringify_keys!)
         put :update, team_id: @team.kyck_id.to_s, id: @ev1.kyck_id.to_s, sevent: new_event_attributes, start_with: "team"
         response.should redirect_to team_events_path(@team)
       end
     end

  end

  describe "#destroy" do
    context "when the logged in user has manage team rights" do

         subject { delete :destroy, team_id: @team.kyck_id, id: @ev1.kyck_id.to_s, start_with: "team" }
         before(:each)  do
           @team.add_staff(@user, {title:"Coach", permission_sets:[PermissionSet::MANAGE_SCHEDULES]})
           OrganizationRepository::TeamRepository.persist @team

           @mock = double
           KyckRegistrar::Actions::DeleteEvent.stub!(:new) { @mock }
         end

         it "should call the delete action" do
           @mock.should_receive(:execute).with(any_args())
           subject
         end

         it "should redirect to the organization's team page" do
           @mock.stub(:execute).with(any_args())
           subject
           response.should redirect_to team_events_path(@team)
         end

         context "json"  do
           it "should respond right" do
             @mock.stub(:execute).with(any_args())
             delete :destroy, team_id: @team.kyck_id.to_s, id: @ev1.kyck_id.to_s, format: :json, start_with: "team"
             response.status.should == 204
           end

         end
       end
  end
end

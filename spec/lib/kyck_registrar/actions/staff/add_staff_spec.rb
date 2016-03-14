require 'spec_helper'

describe KyckRegistrar::Actions::AddStaff do
  let(:requestor) {regular_user}
  let(:org) {create_club}
  let(:location_attributes) do
    {
      address1: "1 Test Street",
      city: "Testville",
      state: "NC",
      zipcode: "11111"
    }
  end

  context 'when user has permission' do


    before(:each) do
      add_user_to_org(requestor, org,  {title: "Registrar", permission_sets: [PermissionSet::MANAGE_STAFF]})
    end

    context "when the user does not exist" do

      let(:input) do
        {"first_name"=>"Les", 
         "last_name"=>"Porter", 
         "email"=>"les@kyck.com", 
         "phone_number"=>"704-663-3333", 
         "title"=>"Title", 
         "role"=>"parttime", 
         "permission_sets"=>""
        }.merge(location_attributes).with_indifferent_access
      end
      subject{KyckRegistrar::Actions::AddStaff.new requestor, org }

      it 'should add and return 1 organization user object after creating the user' do
        expect { 
          subject.execute input
        }.to change {org.get_staff().count}.by(1)
      end

      it "should send a notification" do
        doub_notifier = double(KyckRegistrar.notifier)
        doub_notifier.should_receive(:staff_added)

        subject.notifier = doub_notifier
        subject.execute input
      end

      it "adds a title" do
        res = subject.execute input
        org.get_staff_for_user(res).title.should == "Title"
      end

      it "adds a role" do
        res = subject.execute input
        org.get_staff_for_user(res).role.should == :parttime
      end

      it "broadcasts a created staff" do
        listener = double('listener')
        listener.should_receive(:staff_created).with instance_of Staff
        subject.subscribe(listener)

        subject.execute(input)
      end

      context "when the user params are invalid" do
        it "broadcasts a invalid staff" do
          listener = double('listener')
          listener.should_receive(:invalid_staff).with instance_of Staff
          subject.subscribe(listener)
          input.delete(:email)
          subject.execute(input)
        end
      end

      context "when the user's location data is incomplete" do
        it "broadcasts an invalid staff message:" do
          listener = double("listener")
          listener.should_receive(:invalid_staff).with instance_of Staff
          subject.subscribe(listener)
          input.delete(:address1)
          subject.execute(input)
        end
      end

      context "when the notifier sends an error" do

        let (:notifier) { Object.new}

        before do
          notifier.stub(:staff_added) { raise StandardError.new}
          subject.notifier = notifier
        end

        it "still adds the staff" do
          expect { 
            subject.execute input
          }.to change {org.get_staff().count}.by(1)
        end

        it "broadcasts an error" do
          listener = double('listener')
          listener.should_receive(:notification_failed).with instance_of StandardError
          subject.subscribe(listener)
          subject.execute input
        end

      end

      context "and adding multiple" do

        let(:input2) do
          {"first_name"=>"Les2", 
           "last_name"=>"Porter", 
           "email"=>"les2@kyck.com", 
           "phone_number"=>"704-663-3333", 
           "title"=>"Title234", 
           "role"=>"parttime", 
           "permission_sets"=>""
          }.merge(location_attributes).with_indifferent_access
        end 


        it "adds multiple" do
          expect {
            subject.execute input
            OrganizationRepository.persist!(org)
            subject.execute input2
          }.to change {
            org.get_staff().count}.by(2)   
        end

        it "adds the right stuff" do
          subject.execute input
          OrganizationRepository.persist!(org)
          org._data.reload
          subject.execute input2
          titles = org.get_staff.map(&:title) 
          titles.should include "Title234"
        end


      end
    end

    context "when the user does exist"  do
      let(:existing_user) {regular_user}

      context "and a user id is NOT supplied" do
        let(:input) do
          {
            :email => existing_user.email, 
           :title => "Coach", 
           :permission_sets => ['ManageTeam'], 
           first_name: 'New', 
           last_name: 'Guy' 
          }.merge(location_attributes).with_indifferent_access
        end

        subject{KyckRegistrar::Actions::AddStaff.new requestor, org }

        it 'should add an organization user and return a user object from existing user ' do

          expect { 
            result = subject.execute input
            result.email.should == existing_user.email
          }.to change {org.get_staff().count}.by(1)
        end

        it "should send a notification" do
          doub_notifier = double(KyckRegistrar.notifier)
          doub_notifier.should_receive(:staff_added)
          subject.notifier = doub_notifier
          subject.execute input
        end
      end

      context "and a user id is supplied" do
        let(:input) {{:user_id => existing_user.kyck_id }}

        subject{KyckRegistrar::Actions::AddStaff.new requestor, org }

        it 'should add an organization user and return a user object from existing user ' do
          assert_difference proc {org.get_staff().count} do
            result = subject.execute input
            result.email.should == existing_user.email
            result.first_name.should == existing_user.first_name
          end 
        end

        it "should send a notification" do
          doub_notifier = double(KyckRegistrar.notifier)
          doub_notifier.should_receive(:staff_added)
          subject.notifier = doub_notifier
          subject.execute input
        end
      end
    end

    context "when the user is already on staff"  do
      let(:staff) {regular_user}
      before(:each) do
        add_user_to_org(staff,org, {title: "Coach"})
        UserRepository.persist(staff)
      end
      let(:input) {{:email => staff.email, :title => "Coach", :permission_sets => ['ManageTeam'], first_name: 'New', last_name: 'Guy' }}
      subject do 
        KyckRegistrar::Actions::AddStaff.new requestor, org 
      end

      it "should not add a new staff" do
        assert_no_difference proc {org.get_staff().count} do
          result = subject.execute input
        end 
      end

      it "should not send a notification" do
        doub_notifier = double(KyckRegistrar.notifier)
        doub_notifier.should_not_receive(:staff_added)
        subject.notifier = doub_notifier
        result = subject.execute input
      end

    end
  end

  context 'when user is an admin with permission' do
    it 'should add and return 1 organization user object after creating the user' do

      input = {:email => 'staff1@kyck.com', :title => "Coach", :permission_sets => [] , first_name: 'New', last_name: 'Guy'}.merge(location_attributes).with_indifferent_access

      u = User.build(email: 'orgstaffcurrentuser@test.com', first_name: 'First', last_name: 'Last', kind: 'admin', kyck_id: create_uuid)  
      u = UserRepository.persist(u)
      o = Organization.build(kind: :club, name: 'Test Club', status: :active)
      o = OrganizationRepository.persist(o)
      action = KyckRegistrar::Actions::AddStaff.new u, o
      result = action.execute input

      o.get_staff().count.should == 1

    end

  end

  context 'when user does not have permission to add a permission on a staff' do
    it 'should raise an exception' #do
    #      input = {:email => 'staff_do_not_add@kyck.com', :title => "Coach", :permission_sets => ['ManageOrganization', 'ManageTeams'], first_name: 'New', last_name: 'Guy' }
    #
    #      u = User.build(email: 'test@test.com', first_name: 'First', last_name: 'Last')  
    #      u.kyck_id = create_uuid
    #      UserRepository.persist u
    #
    #      o = Organization.build(kind: :club, name: 'Test Club', status: :active)
    #      OrganizationRepository.persist o
    #      o.add_staff(u, {title:"Registrar", permission_sets: [ 'ManageTeam' ]})
    #      OrganizationRepository.persist o
    #
    #
    #      action = KyckRegistrar::Actions::AddStaff.new u, o
    #      expect {result = action.execute input}.to raise_error KyckRegistrar::PermissionsError
    #
    #    end

  end

  context 'when user does not have permission to add staff' do
    it 'should raise a PermissionsError' do
      input = {:email => 'staff_do_not_add@kyck.com', :title => "Coach", :permission_sets => ['ManageOrganization'], first_name: 'New', last_name: 'Guy' }

      action = KyckRegistrar::Actions::AddStaff.new requestor, org
      expect{ result = action.execute input}.to raise_error KyckRegistrar::PermissionsError

    end

  end


end

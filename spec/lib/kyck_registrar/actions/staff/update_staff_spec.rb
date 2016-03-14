require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateStaff do

      let(:location_attributes) do
        {
          "address1" => "1 Test Street",
          "city" => "Testville",
          "state" => "NC",
          "zipcode" => "11111"
        }
      end
      let(:staff_attributes) do 
        {
          "id" => @staff.kyck_id.to_s, 
          "first_name"=> 'First', 
          "last_name"=> 'Last', 
          "email"=> 'f@l.com', 
          "title"=> 'Big Dog', 
          "phone_number"=> '777-555-4444'
        }
      end

      let(:requestor) do 
        regular_user
      end

      let(:org) do
        org = create_club
      end

      subject do
        UpdateStaff.new requestor, org
      end 
      context "when the user is authorized to update staff" do
        
        before(:each) do
          @staff = org.add_staff(requestor, {title: 'Manage', permission_sets: ["ManageStaff"]})
          l = LocationRepository.persist(Location.build(location_attributes))
          requestor.add_location(l)
          UserRepository.persist requestor
        end

        it "should change the staff title" do
          st= subject.execute staff_attributes
          st.title.should == "Big Dog"
        end

        [:first_name, :last_name, :email, :phone_number].each do |attr|
          it "should change the user #{attr}" do
            st = subject.execute staff_attributes
            st.user.send(attr).should == staff_attributes[attr.to_s]
          end
        end

        it "should broadcast sucess" do
          listener = double('listener')
          listener.should_receive(:staff_updated).with instance_of Staff
          subject.subscribe(listener)

          subject.execute(staff_attributes)
        end

        context "when the staff params are invalid" do
          it "broadcasts invalid staff" do
            listener = double('listener')
            listener.should_receive(:staff_invalid).with instance_of Staff
            subject.subscribe(listener)
            staff_attributes["email"] = ""
            subject.execute(staff_attributes)
          end     
        
        end

        context "when the location data is not provided" do

          context "and the staff already has location data" do

            it "updates the staff" do
              st = subject.execute staff_attributes
              st.user.first_name.should == "First"
            end

          end

          context "and the staff does not have location data" do

            let(:requestor2) do 
              regular_user
            end

            subject do
              UpdateStaff.new requestor2, org
            end 
            
            before(:each) do
              @staff = org.add_staff(requestor2, {title: 'Manage', permission_sets: ["ManageStaff"]})
              UserRepository.persist requestor2
            end

            it "broadcasts staff invalid" do
              listener = double('listener')
              listener.should_receive(:staff_invalid).with instance_of Staff
              subject.subscribe(listener)
              subject.execute(staff_attributes)
            end
          end 
        end

        context "when location data is provided" do
          context "and the staff does not have previous location data" do
            
            subject do
              UpdateStaff.new requestor, org
            end 
            
            before(:each) do
              @staff = org.add_staff(requestor, {title: 'Manage', permission_sets: ["ManageStaff"]})
              UserRepository.persist requestor
            end

            it "updates the staff" do
              st = subject.execute staff_attributes.merge(location_attributes).with_indifferent_access
              st.user.locations.should_not be_empty
            end
          end
        end
      end

      context "when the requestor does not have authorization to update staff" do
        before(:each) do
          @staff = org.add_staff(requestor, {title: 'Volunteer'})
          UserRepository.persist org
        end
      
        it "should throw a permissions error" do
          expect {subject.execute staff_attributes}.to raise_error KyckRegistrar::PermissionsError 
        end
      end
    end
  end
end

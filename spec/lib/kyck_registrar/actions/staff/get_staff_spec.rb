require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetStaff do

      def add_staff(user, org, permission_sets=[])
        org.add_staff(user, {title: 'Staff', permission_sets: permission_sets})
        UserRepository.persist! user
                
      end

      describe "#initialize" do
        it "takes a requestor and staffed item" do
          expect {described_class.new(regular_user, create_sanctioning_body)}.to_not raise_error
        end
      end

      describe "#execute" do
        let(:org) { create_sanctioning_body}
        let(:requestor) {regular_user}
        context "when no organization is provided" do
          subject { described_class.new(requestor) } 

          before(:each) do
            add_staff(requestor, org )
          end

          it "returns the staff for the requestor" do
            staff = subject.execute
            staff.count.should == 1
            staff[0].user.id.should == requestor.id
          end

        end

        context "when an organization is provided" do
          subject { described_class.new(requestor, org) } 
          before(:each) do
            @staff_user1 = regular_user
            @staff_user2 = regular_user
            add_staff(@staff_user1, org)
            add_staff(@staff_user2, org)
          end

          context "and the user has the right to see staff" do
            before(:each) do
              add_staff(requestor, org, [ PermissionSet::MANAGE_STAFF ])
            end

            it "returns the staff for the organization" do
              
              staff = subject.execute
              staff.count.should == 3
              ids = staff.map {|s| s.user.id}
              ids.should include @staff_user1.id
              ids.should include @staff_user2.id
            end

            context "and the user wants to manage that staff" do

              it "returns the staff for the organization" do
                staff = subject.execute({permission_sets:[PermissionSet::MANAGE_STAFF]})
                staff.count.should == 3
                ids = staff.map {|s| s.user.id}
                ids.should include @staff_user1.id
                ids.should include @staff_user2.id
              end
            end

          end
          context "and the requestor does not have the right to see staff" do
            it "should throw a Permissions error" do
              expect {subject.execute({permission_sets:[PermissionSet::MANAGE_STAFF]})}.to raise_error PermissionsError  
            end
          end

        end
      end
    end
  end
end

require 'spec_helper'

module KyckRegistrar
  module Actions
    describe StaffBackgroundCheck do
      let(:bg_data) { "123456" }
      let(:requestor) { regular_user }
      let(:org) { create_club }
      let(:staff) { regular_user }

      before(:each) do
        org.add_staff(requestor, { title: 'Admin', permission_sets: ["ManageStaff"]})
        UserRepository.persist requestor
        @staff = org.add_staff(staff, { title: 'Staff'})
        UserRepository.persist staff
        @listener = double('listener')
        subject.subscribe(@listener)
      end

      context "when the user is authorized to update the background check" do
        subject { StaffBackgroundCheck.new(requestor, @staff.user) }

        context "and the background check data is valid" do

          it "broadcaasts a background check updated message" do
            expect(@listener).to receive(:background_check_updated).with instance_of(User)
            subject.execute(bg_data)
          end

          it "updates the staff's background check" do
            subject.execute(bg_data)
            expect(@staff.user.background_check).to eq("123456")
          end
        end

        context "and the background check data is invalid" do
          
          it "does not update the staff's background check data" do
            expect(@listener).to receive(:background_check_failed).with instance_of(User)
            subject.execute("123")
          end
        end
      end
    end
  end
end

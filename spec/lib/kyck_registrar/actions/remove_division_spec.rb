require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveDivision do

      subject { KyckRegistrar::Actions::RemoveDivision }

      describe "#new" do
        it "should take a requestor" do
          expect { subject.new }.to raise_error ArgumentError
        end

        it "should take a division" do
          expect { subject.new(User.new) }.to raise_error ArgumentError
        end

        it "should take a division" do
          expect { subject.new(User.new, Division.new) }.to_not raise_error ArgumentError
        end
      end

      describe "#execute" do
        subject{KyckRegistrar::Actions::RemoveDivision}
        let(:comp) { create_competition }
        let(:division) { create_division_for_competition(comp) }

        context "when the requestor has permission to delete the competition" do
          describe "requestor is staff" do
            let(:requestor) do 
              u = regular_user
              comp.add_staff(u, title:"Dood", permission_sets: [PermissionSet::MANAGE_COMPETITION])
              UserRepository.persist(u)
              u
            end 

            it "should tell the repo to remove the competition" do
              mock = double
              mock.should_receive(:delete_by_id).with(division.id)

              action = subject.new(requestor, division)
              action.repository = mock

              action.execute
            end
          end

          describe "requestor is admin" do
            let(:requestor) { admin_user }

            it "should tell the repo to remove the competition" do
              mock = double
              mock.should_receive(:delete_by_id).with(division.id)

              action = subject.new(requestor, division)
              action.repository = mock
              action.execute
            end
          end
        end

        context "when the requestor does not have permission to delete the competition" do
          let(:requestor) { regular_user }

          it "should raise an error" do
            action = subject.new(requestor, division)
            expect { action.execute }.to raise_error PermissionsError
          end
        end
      end
    end
  end
end

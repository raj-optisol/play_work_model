# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveStaff do

      let(:requestor) { regular_user }
      let(:existing_staff) do
        staff = regular_user
        s = club.add_staff(staff, title: 'Manager')
        UserRepository.persist staff
        s
      end
      let(:club) { create_club }
      context 'when the requester has the right permissions' do
        subject { described_class.new(requestor, club) }

        before(:each) do
          add_user_to_org(requestor,
                          club,
                          title: 'Manager',
                          permission_sets: [PermissionSet::MANAGE_STAFF])
        end

        it 'should remove the staff member' do
          existing_staff
          expect do
            subject.execute(id: existing_staff.kyck_id.to_s)
          end.to change { club.staff.count }.by(-1)
        end

        context "when the staff member is not found" do
          it "raise a error" do
            expect { subject.execute(id: SecureRandom.uuid) }.to(
              raise_error)
          end
        end
      end

      context 'when the requester does not have the right permissions' do
        subject { described_class.new(requestor, club) }

        it 'should raise an error' do
          expect do
            subject.execute(id: existing_staff.kyck_id.to_s)
          end.to raise_error KyckRegistrar::PermissionsError
        end
      end
    end
  end
end

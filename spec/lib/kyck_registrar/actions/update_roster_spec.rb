require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateRoster do
      let (:club) { create_club }

      let(:team) { team = create_team_for_organization(club) }

      let!(:roster) { team.create_roster(name:'Roster One') }

      describe '#new' do
        it 'takes a requestor' do
          expect { KyckRegistrar::Actions::UpdateRoster.new }.to raise_error
        end

        it 'takes a roster' do
          expect do
            KyckRegistrar::Actions::UpdateRoster.new(User.new)
          end.to raise_error
        end
      end

      context 'when the requestor has manage roster rights' do

        let(:requestor) do
          user = regular_user
          team.add_staff(user,
                         title:'Title',
                         permission_sets:[PermissionSet::MANAGE_ROSTER])
          OrganizationRepository::TeamRepository.persist! team
          user
        end

        let(:roster_attributes) { {name: 'Another Roster'} }

        subject { KyckRegistrar::Actions::UpdateRoster.new(requestor,
                                                           roster) }

        it 'should set the new values on the roster' do
          changed_roster = subject.execute roster_attributes
          changed_roster.name.should == 'Another Roster'
        end

        context 'when a roster is not supplied' do
          it 'should throw an error' do
            mock = double
            subject.repository = double
            mock.stub!(:persist).with(any_args)
            expect {s ubject.execute roster_attributes }.to raise_error
          end
        end
      end  # END requestor has manage rights

      context 'when the requestor does not have manage roster rights' do
        let(:requestor) { regular_user }
        let(:roster_attributes) { {name: 'Another Roster'} }

        subject {KyckRegistrar::Actions::UpdateRoster.new(requestor, roster) }

        context 'when a roster id is not supplied' do
          it 'should throw an error' do
            expect { subject.execute roster_attributes }.to raise_error
          end
        end
      end  # END requestor no manage rights
    end
  end
end


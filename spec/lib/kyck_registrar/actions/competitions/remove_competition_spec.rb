require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveCompetition do

      subject { KyckRegistrar::Actions::RemoveCompetition }

      describe '#new' do
        it 'should take a requestor' do
          expect { subject.new }.to raise_error ArgumentError
        end

        it 'should take a competition' do
          expect { subject.new(User.new) }.to raise_error ArgumentError
        end

        it 'should take a competition' do
          expect { subject.new(User.new, Competition.new) }.to_not raise_error ArgumentError
        end
      end

      describe '#execute' do
        subject { KyckRegistrar::Actions::RemoveCompetition }
        let(:comp) { create_competition }

        context 'when the requestor has permission to delete the competition' do
          describe 'requestor is staff' do
            let(:requestor) { regular_user }

            before do
              add_user_to_org(requestor, comp, title:'Dood', permission_sets: [PermissionSet::MANAGE_COMPETITION])
            end

            it 'should tell the repo to remove the competition' do
              mock = double
              mock.should_receive(:delete_by_id).with(comp.id)

              action = subject.new(requestor, comp)
              action.repository = mock

              action.execute
            end
          end

          describe 'requestor is admin' do
            let(:requestor) {
              admin_user
            }

            it 'should tell the repo to remove the competition' do
              mock = double
              mock.should_receive(:delete_by_id).with(comp.id)

              action = subject.new(requestor, comp)
              action.repository = mock

              action.execute
            end
          end
        end

        context 'when the requestor does not have permission to delete the competition' do
          let(:requestor) {
            regular_user
          }

          it 'should raise an error' do
            action = subject.new(requestor, comp)
            expect { action.execute }.to raise_error PermissionsError
          end

        end
      end
    end
  end
end

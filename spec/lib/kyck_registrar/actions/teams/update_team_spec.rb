# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateTeam do
      describe '#new' do
        it 'takes a requestor' do
          expect { described_class.new }.to raise_error ArgumentError
        end

        it 'takes an org' do
          u = User.new
          expect { described_class.new(u) }.to raise_error ArgumentError
        end
      end

      context 'when the requestor has manage team rights' do
        let(:club) { create_club }

        let(:team) { create_team_for_organization(club) }

        let(:requestor) do
          user = regular_user
          club.add_staff(user,
                         title: 'Title',
                         permission_sets: [PermissionSet::MANAGE_TEAM]
                        )
          OrganizationRepository.persist club
          user
        end

        let(:team_attributes) do
          { name: 'Another team',
            born_after: (Date.today - 10.years).to_s,
            gender: :female }.with_indifferent_access
        end

        subject { KyckRegistrar::Actions::UpdateTeam.new(requestor, team) }

        it 'should set the new values on the team' do
          changed_team = subject.execute(
            team_attributes.merge(id: team.id)
          )
          assert_equal changed_team.name, 'Another team'
          assert_equal changed_team.born_after.to_s, (Date.today - 10.years).to_s
          changed_team.gender.should == :female
        end

        context 'when a team id is not supplied' do
          it 'should throw an error' do
            mock = double
            subject.team_repository = double
            mock.stub(:persist).with(any_args)
            expect { subject.execute team_attributes }.to raise_error
          end
        end
      end
    end
  end
end

# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateTeam do
      let(:requestor) { regular_user }
      let(:club) { create_club }

      describe '#initialize' do
        it 'takes a requestor and a club' do
          CreateTeam.new(requestor, club)
        end
      end

      describe '#execute' do
        let(:input) do
          { name: 'TEAM 1',
            born_after: (Date.today - 12.years),
            gender: 'male',
            avatar: 'frbrrt_jersey' }
        end
        before(:each) do
          club.add_staff(
            requestor,
            permission_sets: [PermissionSet::MANAGE_TEAM])
          OrganizationRepository.persist club
          @subject = CreateTeam.new(requestor, club)
        end

        it 'adds the team to the club' do
          expect do
            @subject.execute(input)
          end.to change { club.teams.count }.by(1)
        end

        it 'has an avatar' do
          team = @subject.execute(input)
          team.avatar.should == 'frbrrt_jersey'
        end

        it 'creates official roster on newly created team' do
          team = @subject.execute(input)
          team.rosters.count.should == 1
        end

      end # END EXECUTE
    end
  end
end

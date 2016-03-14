require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetUncarded do

      let(:uscs) { create_sanctioning_body({name: 'USCS'})}
      let(:requestor) { regular_user }
      let(:club) { create_club }
      let(:uncarded_player) { create_player_for_organization(club) }
      let(:team) { create_team_for_organization(club) }
      let(:staff) { add_user_to_org(regular_user, team) }
      let(:uncarded_staff) { add_user_to_org(regular_user, team) }
      let(:roster) { create_roster_for_team(team) }
      let!(:player) { add_player_to_roster(roster) }
      let(:player_card) { uscs.card_user_for_organization(player.user, club) }
      let(:staff_card) { uscs.card_user_for_organization(staff.user, club, kind: :staff) }
      let(:team2) { create_team_for_organization(club) }
      let(:roster2) { create_roster_for_team(team2) }
      let!(:player3) { add_player_to_roster(roster2) }
      let!(:player4) { create_player_for_organization(club) }


      describe '#execute' do
        subject { described_class.new(requestor, club) }

        before do
          s = add_user_to_org(requestor, club, permission_sets: [PermissionSet::REQUEST_CARD])

          player_card
          staff_card
          uncarded_player
          uncarded_staff
          club.add_player(player3.user)
          OrganizationRepository.persist! club
          player4
        end

        it 'returns the players and staff not carded' do
          members = subject.execute
          member_ids = members.map{|m| m.user.id}
          member_ids.should include(uncarded_player.user.id), 'Uncarded Player is missing'
          member_ids.should include(player3.user.id), 'Player 3 is missing'
          member_ids.should include(player4.user.id), 'Player 4 is missing'
        end

        it 'returns the staff' do
          members = subject.execute
          member_ids = members.map{|m| m.user.id}.should include(uncarded_staff.user.id)
        end

        context 'when a team_id is supplied' do
          it 'filters based on team' do
            result = subject.execute(team_conditions: {kyck_id: team2.kyck_id})
            result.count.should == 1
            result.first.user.kyck_id.should == player3.user.kyck_id
          end
        end

        context 'when last_name is supplid' do

          it 'filters the results' do
            result = subject.execute({user_conditions: {last_name_like: player3.user.last_name}})
            result.count.should == 1
            result.first.user.kyck_id.should == player3.user.kyck_id
          end


        end
      end


    end
  end
end

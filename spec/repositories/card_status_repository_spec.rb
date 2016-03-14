# encoding: UTF-8
require 'spec_helper'
module CardStatusRepository
  describe 'Card Status' do
    let(:sb) { create_sanctioning_body }
    let(:club) { create_club }
    let(:team) { create_team_for_organization(club) }
    let(:roster) { create_roster_for_team(team) }

    let(:player) { add_player_to_roster(roster) }
    let(:staff) { add_user_to_org(regular_user, team) }
    let(:player_card) do
      sb.card_user_for_organization(player.user,
                                    club,
                                    status: :approved)
    end
    let(:staff_card) do
      sb.card_user_for_organization(
        staff.user,
        club,
        kind: :staff,
        status: :approved)
    end

    let(:uncarded_player) do
      add_player_to_roster(roster)
    end
    let(:uncarded_player2) { create_player_for_organization(club) }
    let(:uncarded_staff) { add_user_to_org(regular_user, team) }

    let(:team2) { create_team_for_organization(club) }
    let(:roster2) { create_roster_for_team(team2) }
    let!(:player2) { add_player_to_roster(roster2) }

    let(:club2) { create_club }
    let(:team3) { create_team_for_organization(club2) }
    let(:roster3) { create_roster_for_team(team3) }
    let(:staff2) { add_user_to_org(regular_user, club2) }
    let(:staff_card2) do
      sb.card_user_for_organization(staff2.user,
                                    club,
                                    status: :approved,
                                    kind: :staff)
    end

    let(:uncarded_staff2) { add_user_to_org(regular_user, club2) }
    let(:uncarded_player3) { create_player_for_organization(club2) }
    let(:uncarded_player_club2) do
      p = roster3.add_player(uncarded_player.user)
      TeamRepository::RosterRepository.persist roster3
      p
    end

    before do
      # Club 1
      player_card
      staff_card
      uncarded_player
      uncarded_staff
      uncarded_player2

      # Club 2
      staff_card2
      uncarded_staff2
      uncarded_player3
      uncarded_player_club2

      @users_on_teams = [
        uncarded_player_club2.user.kyck_id,
        uncarded_staff.user.kyck_id]
    end

    context 'For an Organization' do
      describe '.card_status_summary_for_obj' do
        it 'returns hash of player/staff card counts' do
          status = CardStatusRepository.card_status_summary_for_obj(sb,
                                                                    club)
          obj = { 'uncarded_staff_count' => 1,
                  'uncarded_player_count' => 3,
                  'carded_staff_count' => 1,
                  'carded_player_count' => 1,
                  'carded' => 2,
                  'uncarded' => 4 }.to_json
          status.to_json.should be_json_eql(obj)
        end
      end

      describe '.get_uncarded_for_sb_and_item' do
        subject do
          CardStatusRepository.get_uncarded_for_sb_and_item(sb, club)
        end
        it 'returns count for all uncarded players and staff' do
          assert_equal subject.count, 4
        end

        it 'returns the right team count for all uncarded players and staff' do
          with_teams = subject.select do |c|
            c.entities.count > 0 && c.entities.first.is_a?(Team)
          end
          assert_equal with_teams.count, 3
        end

        context 'when user conditions are specified' do
          let(:user_input) do
            { user_conditions: { last_name: uncarded_player.user.last_name } }
          end
          it 'returns the right user' do
            cs = CardStatusRepository.get_uncarded_for_sb_and_item(sb,
                                                                   club,
                                                                   user_input)
            assert_equal cs.count, 1
            assert_equal cs.first.user.kyck_id, uncarded_player.user.kyck_id
          end

        end
      end

      describe '.get_uncarded_players_pipeline_for_sb_and_item' do
        subject do
          CardStatusRepository
            .get_uncarded_players_pipeline_for_sb_and_item(sb, club)
        end
        it 'returns count for all uncarded players' do
          subject.count.should == 3
        end
      end

      describe '.get_uncarded_staff_pipeline_for_sb_and_item' do
        subject do
          CardStatusRepository
            .get_uncarded_staff_pipeline_for_sb_and_item(sb, club)
        end
        it 'returns count for all uncarded staff' do
          subject.count.should == 1
        end
      end

      describe '.get_player_cards_pipeline_for_sb_and_item' do
        subject do
          CardStatusRepository.get_player_cards_pipeline_for_sb_and_item(sb,
                                                                         club)
        end
        it 'returns count for all carded players' do
          subject.count.should == 1
        end
      end

      describe '.get_staff_cards_pipeline_for_sb_and_item' do
        subject do
          CardStatusRepository.get_staff_cards_pipeline_for_sb_and_item(sb,
                                                                        club)
        end

        it 'returns count for all carded staff' do
          subject.count.should == 1
        end
      end
    end  # END CARD STATUS FOR Organization
  end
end

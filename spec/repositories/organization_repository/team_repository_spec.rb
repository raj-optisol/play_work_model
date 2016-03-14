module OrganizationRepository
  describe TeamRepository do
    let(:club) { create_club }
    let(:team) { create_team_for_organization(club) }
    let(:roster) { create_roster_for_team(team) }
    let(:player) { add_player_to_roster(roster) }
    let!(:user) { player.user }
    describe 'get teams for player and club' do
      it 'gets the teams' do
        result = described_class.get_teams_for_player_and_organization(user,
                                                                       club)
        result.map(&:kyck_id).should include(team.kyck_id)
      end
    end

    describe 'get teams for staff and, club' do
      let!(:staff) { add_user_to_org(user, team) }
      let(:user) { regular_user }

      it 'gets the teams' do
        result = described_class.get_teams_for_staff_and_organization(user,
                                                                      club)
        result.map(&:kyck_id).should include(team.kyck_id)
      end
    end

    describe '#open_team_for_org!' do
      subject { described_class.open_team_for_org!(club) }
      context 'when the open team does not exist' do
        it 'creates it' do
          subject.should_not be_nil
        end

        it 'creates an open team' do
          subject.should be_open
        end

        it 'creates an official roster' do
          subject.official_roster.should_not be_nil
        end
      end

      context 'when the open team exists' do
        let!(:open_team) { create_team_for_organization(club, open: true) }
        it 'returns it' do
          subject.kyck_id.should == open_team.kyck_id
        end
      end
    end
  end
end

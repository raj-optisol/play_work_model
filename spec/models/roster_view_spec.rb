# encoding: UTF-8
require 'spec_helper'

describe RosterView do

  let(:roster_spot_1) do
    { 'first_name' => 'Hot',
      'player' => { 'jersey_number' => '12' },
      'kyck_id' => 'fc212c1a-f639-47b4-aa54-0e9eb92ab467',
      'birthdate' => 12.years.ago.to_java,
      'last_name' => 'Rod',
      'roster' => { 'name' => 'Roster' },
      'cards' => {
        'birthdate' => 12.years.ago.to_java,
        'expires_on' => 1.year.from_now.to_i
      }
    }
  end

  let(:staff_spot_1) do
    { 'first_name' => 'Stafft',
      'staff' => { 'title' => 'coach', 'id' => '1234' },
      'kyck_id' => 'fc212c1a-f639-47b4-aa54-0e9eb92ab467',
      'last_name' => 'Rod',
      'roster' => { 'name' => 'Roster' },
      'cards' => {
        'birthdate' => 12.years.ago.to_java,
        'expires_on' => 1.year.from_now.to_i
      }
    }
  end

  let(:team_options) do
    {
      name: 'Team',
      id: '23453',
      age_group: 19,
      born_after: 14.years.ago
    }
  end

  let(:organization_options) do
    {
      name: 'Club',
      avatar_url:  'https://image.com/img.png',
      id: '1235'
    }
  end

  let(:league_options) do
    {
      name: 'League'
    }
  end

  let(:sanctioned) { true }

  subject do
    described_class.new([roster_spot_1, staff_spot_1],
                        team_options,
                        organization_options,
                        league_options,
                        sanctioned)
  end

  describe '#name' do
    it { expect(subject.name).to eql('Roster') }
  end

  describe '#sanctioned?' do
    context 'when the roster is sanctioned' do
      it 'is true' do
        expect(subject.sanctioned?).to be_true
      end
    end

    context 'when the roster is not sanctioned' do
      let(:sanctioned) { false }
      it 'is false' do
        expect(subject.sanctioned?).to be_false
      end
    end
  end

  describe '#club_avatar_url' do
    it 'returns the club avatar url' do
      expect(subject.club_avatar_url).to eql('https://image.com/img.png')
    end
  end

  describe '#club_name' do
    it 'returns the club name' do
      expect(subject.club_name).to eql('Club')
    end
  end
  
  describe '#club_id' do
    it 'returns the club id' do
      expect(subject.club_id).to eql('1235')
    end
  end

  describe '#team_name' do
    it 'returns the team name' do
      expect(subject.team_name).to eql('Team')
    end
  end

  describe '#team_id' do
    it 'returns the team id' do
      expect(subject.team_id).to eql('23453')
    end
  end

  describe '#team_age_group' do
    it 'returns the team age_group' do
      expect(subject.team_age_group).to eql(19)
    end
  end

  describe '#team_born_after' do
    it 'returns the team born_after' do
      expect(subject.team_born_after).to eql(team_options[:born_after])
    end
  end

  describe '#league_name' do
    it 'returns the league name' do
      expect(subject.league_name).to eql('League')
    end
  end

  describe '#staff' do
    it 'returns an array of RosterStaffRows' do
      at_least_one_staff = false
      subject.staff.each do  |s|
        assert s.is_a?(RosterStaffRow)
        at_least_one_staff = true
      end

      assert at_least_one_staff
    end
  end

  describe '#players' do
    it 'returns an array of RosterPlayerRows' do
      at_least_one_player = false
      subject.players.each do  |s|
        assert s.is_a?(RosterPlayerRow)
        at_least_one_player = true
      end

      assert at_least_one_player
    end
  end
end

# encoding: UTF-8
require 'spec_helper'

describe RosterPlayerRow do

  let(:row) do
    { 'first_name' => 'Hot',
      'player' => { 'jersey_number' => '12' },
      'kyck_id' => 'fc212c1a-f639-47b4-aa54-0e9eb92ab467',
      'birthdate' => Time.now.to_java,
      'last_name' => 'Rod',
      'roster' => { 'name' => 'Roster' },
      'cards' => {
        'birthdate' => Time.now.to_java,
        'expires_on' => 1.year.from_now.to_i,
        'first_name' => 'Hottie',
        'last_name' => 'Roddie',
        'status' => 'approved',
        'out_Card__carded_for' => { 'kyck_id' => club_id }
      }
    }
  end

  let(:club_id) { '12345' }

  subject { described_class.new(row, club_id) }

  describe '#first_name' do
    context 'when the card has a first name' do
      it 'returns the first name from the card' do
        expect(subject.first_name).to eql('Hottie')
      end
    end

    context 'when the user does not have a card' do
      before do
        row['cards'] = []
      end

      it 'returns the first name of the player' do
        expect(subject.first_name).to eql('Hot')
      end
    end

    context "when the user has 2 cards" do
      before do
        row['cards'] = [
          {
            'birthdate' => Time.now.to_java,
            'expires_on' => 1.year.from_now.to_i,
            'first_name' => 'Hottie',
            'last_name' => 'Roddie',
            'status' => 'approved',
            'out_Card__carded_for' => { 'kyck_id' => club_id }

          },
          {
            'birthdate' => Time.now.to_java,
            'expires_on' => 1.month.ago.to_i,
            'first_name' => 'Expired',
            'last_name' => 'Roddie',
            'status' => 'approved',
            'out_Card__carded_for' => { 'kyck_id' => club_id }

          }
        ]
      end
      it 'returns the first name from the latest card' do
        expect(subject.first_name).to eql('Hottie')
      end
    end
  end

  describe '#last_name' do
    context 'when the card has a last name' do
      it 'returns the last name from the card' do
        expect(subject.last_name).to eql('Roddie')
      end
    end

    context 'when the user does not have a card' do
      before do
        row['cards'] = []
      end

      it 'returns the last name of the player' do
        expect(subject.last_name).to eql('Rod')
      end
    end
  end

  describe '#birthdate' do
    context 'when the player has a card' do
      it 'returns the birthdate from the card' do
        expect(subject.birthdate).to(
          eql Time.at(row['cards']['birthdate'].getTime / 1000))
      end end

    context 'when the user does not have a card' do
      before do
        row['cards'] = []
      end

      it 'returns the birthdate of the player' do
        expect(subject.birthdate).to eql Time.at(
          row['birthdate'].getTime / 1000)
      end
    end

    context 'when neither the card not the player has a birtdate value' do
      before do
        row.delete('birthdate')
        row['cards'].delete('birthdate')
      end

      it 'returns nil' do
        expect(subject.birthdate).to be_nil
      end
    end
  end

  describe '#player_id' do
    context 'when the user has a migrated_id' do
      before do
        row['migrated_id'] = 1111
      end
      it 'returns the migrated_id' do
        expect(subject.player_id).to eql(1111)
      end
    end
    context 'when the user does not have a migrated_id' do
      it 'returns the truncated kyck_id' do
        expect(subject.player_id).to eql('fc212c1a-f6')
      end
    end
  end

  describe '#card_expiration' do
    it 'returns the card expiration' do
      expect(subject.card_expiration).to eql(
        Time.at(row['cards']['expires_on']))
    end
  end

  describe '#jersey_number' do
    it 'returns the jersey number' do
      expect(subject.jersey_number).to eql(row['player']['jersey_number'])
    end
  end

  describe '#cards' do

    it 'returns the cards' do
      expect(subject.cards.count).to eql(1)
    end
    context 'when none of the cards are approved' do
      before do
        row['cards']['status'] = 'expired'
      end

      it 'returns no cards' do
        expect(subject.cards).to be_empty
      end
    end

    context 'when none of the cards are for the current org' do
      subject { described_class.new(row, '12') }
      it 'returns no cards' do
        expect(subject.cards).to be_empty
      end
    end
  end
end

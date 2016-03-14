# encoding: UTF-8
require 'spec_helper'

describe RosterStaffRow do

  let(:row) do
    { 'first_name' => 'Hot',
      'staff' => { 'title' => 'Coach' },
      'kyck_id' => 'fc212c1a-f639-47b4-aa54-0e9eb92ab467',
      'last_name' => 'Rod',
      'roster' => { 'name' => 'Roster' },
      'cards' => {
        'expires_on' => 1.year.from_now.to_i,
        'first_name' => 'Hottie',
        'last_name' => 'Roddie',
        'out_Card__carded_for' => {'kyck_id' => '1234'},
        'status' => 'approved'
      }
    }
  end

  subject { described_class.new(row, '1234') }

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

      it 'returns the first name of the staff' do
        expect(subject.first_name).to eql('Hot')
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

      it 'returns the last name of the staff' do
        expect(subject.last_name).to eql('Rod')
      end
    end
  end

  describe '#staff_id' do
    context 'when the user has a migrated_id' do
      before do
        row['migrated_id'] = 1111
      end
      it 'returns the migrated_id' do
        expect(subject.staff_id).to eql(1111)
      end
    end
    context 'when the user does not have a migrated_id' do
      it 'returns the truncated kyck_id' do
        expect(subject.staff_id).to eql('fc212c1a-f6')
      end
    end
  end

  describe '#card_expiration' do
    it 'returns the card expiration' do
      expect(subject.card_expiration).to eql(
        Time.at(row['cards']['expires_on']))
    end
  end

  describe '#title' do
    it 'returns the title' do
      expect(subject.title).to eql(row['staff']['title'])
    end
  end
end

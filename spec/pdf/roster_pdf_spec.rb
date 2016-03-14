# encoding: UTF-8
require 'spec_helper'

describe RosterPdf do

  describe '#render' do
    let(:club_id) { '1234' }
    let(:roster_spot_1) do
      { 'first_name' => 'Hot',
        'player' => { 'jersey_number' => '12' },
        'kyck_id' => 'fc212c1a-f639-47b4-aa54-0e9eb92ab467',
        'birthdate' => Time.at(12.years.ago.to_i).to_java,
        'last_name' => 'Rod',
        'roster' => { 'name' => 'Roster' },
        'cards' => {
          'birthdate' => Time.at(12.years.ago.to_i).to_java,
          'expires_on' => 1.year.from_now.to_i,
          'out_Card__carded_for' => { 'kyck_id' => club_id },
          'status' => 'approved'
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
          'birthdate' => Time.at(12.years.ago.to_i).to_java,
          'expires_on' => 1.year.from_now.to_i,
          'out_Card__carded_for' => { 'kyck_id' => club_id },
          'status' => 'approved'
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
        id: club_id
      }
    end

    let(:league_options) do
      {
        name: 'League'
      }
    end

    let(:sanctioned) { true }

    let(:roster_view) do
      RosterView.new([roster_spot_1, staff_spot_1],
                     team_options,
                     organization_options,
                     league_options,
                     sanctioned)
    end

    subject do
      described_class.new(roster_view)
    end

    context 'when a player has no birthdate' do
      before do
        roster_spot_1['birthdate'] = ''
        roster_spot_1['cards'].delete('birthdate')
      end

      it "doesn't fail" do
        pdf = RosterPdf.new(roster_view)
        PDF::Inspector::Text.analyze(pdf.render)
      end
    end

    context 'when the card does not have a birthdate but the player does' do
      before do
        roster_spot_1['cards'].delete('birthdate')
      end

      it "doesn't fail" do
        pdf = RosterPdf.new(roster_view)
        PDF::Inspector::Text.analyze(pdf.render)
      end
    end

    context "when the player has cards" do
      it 'does not show NO CARD' do
        pdf = RosterPdf.new(roster_view)
        text = PDF::Inspector::Text.analyze(pdf.render)
        text.strings.should_not include("NO CARD")
      end
    end

    context 'when everything is null' do
      let(:roster_view) do
        RosterView.new([], {}, {})
      end

      it "doesn't fail" do
        pdf = RosterPdf.new(roster_view)
        PDF::Inspector::Text.analyze(pdf.render)
      end
    end
  end
end

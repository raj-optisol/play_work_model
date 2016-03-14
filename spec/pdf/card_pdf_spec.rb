# encoding: UTF-8
require 'spec_helper'

describe CardPdf do
  let(:user) { regular_user }
  let(:club) { create_club }
  let(:uscs) { create_sanctioning_body }

  describe '#render' do
    subject(:pdf) { described_class.new(cards, view) }

    context 'when a player has no birthdate' do
      let(:view) { nil }
      let(:cards) { [create_card(user, club, uscs).extend(CardRepresenter)] }

      it 'should not fail' do
        cards.first.birthdate = nil
        PDF::Inspector::Text.analyze(pdf.render)
      end

      it 'should not display the current date' do
        cards.first.birthdate = nil
        text = PDF::Inspector::Text.analyze(pdf.render)

        expect(text.strings).not_to include(DateTime.now.strftime('%m/%d/%Y'))
      end
    end
  end
end

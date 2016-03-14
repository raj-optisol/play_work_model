# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CardsForCompetition do
      let(:uscs) { create_sanctioning_body }
      let(:requestor) { regular_user }
      let(:club) { create_club }
      let(:player) { create_player_for_organization(club) }
      let(:player_card) { uscs.card_user_for_organization(player.user, club) }
      let(:comp) { create_competition }

      let(:player2) { create_player_for_organization(club) }
      let(:player_card2) { uscs.card_user_for_organization(player2.user, club) }

      describe '#execute' do
        subject { described_class.new(requestor, uscs, comp) }
        before do
          player_card._data.processor = comp._data
          player_card._data.save
          player_card2._data.processor = comp._data
          player_card2._data.save
          add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
        end

        it 'returns the right cards' do
          cards = subject.execute
          cards.count.should == 2 #both player cards
          cards.map(&:kyck_id).should include(player_card.kyck_id)
        end
      end
    end
  end
end

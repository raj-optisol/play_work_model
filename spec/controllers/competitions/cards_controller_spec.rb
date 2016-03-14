# encoding: UTF-8
require 'spec_helper'

module Competitions
  describe CardsController do
    include Devise::TestHelpers
    let(:requestor) { regular_user }
    let(:uscs) { create_sanctioning_body(name: 'USCS') }
    let(:club) { create_club }
    let(:player1) { regular_user }
    let(:player2) { regular_user }
    let(:staff) { regular_user }
    let(:player1_card) { create_card(player1, club, uscs, order_id: '1234') }
    let(:player2_card) { create_card(player2, club, uscs) }
    let(:staff_card) { create_card(staff, club, uscs, kind: :staff) }
    let(:cards) { [player1_card, player2_card, staff_card] }
    let(:comp) { create_competition }
    let(:team) { create_team_for_organization(club) }
    let(:roster) { create_roster_for_team(team) }

    before(:each) do
      sign_in_user(requestor)
    end

    describe '#update' do
      context 'when saving a card update' do
        it 'redirects back to edit card' do
          stub_execute_action(KyckRegistrar::Actions::UpdateCard,
                              { 'first_name' => 'Bill' },
                              player1_card)
          put :update, competition_id: comp.kyck_id, id: player1_card, card: { first_name: 'Bill' }, step: 'save'
          response.should redirect_to edit_competition_card_path(comp, player1_card)
        end
      end
    end

    describe '#index' do
      context 'for a sanctioning body' do
        context 'for a competition' do
          before do
            player2_card._data.processor = comp._data
            CardRepository.persist(player2_card)
            add_user_to_org(requestor, comp, permission_sets: [PermissionSet.for_competition])
          end

          it 'returns the cards that competition can process' do
            mock_execute_action(
              KyckRegistrar::Actions::CardsForCompetition,
              {
                limit: 25,
                offset: 0,
                card_conditions: {}
              },
              [player2_card]
            )
            get :index, format: :json, competition_id: comp.kyck_id
          end
        end

      end
    end

    describe '#approve' do
      context 'for a competition' do
        let(:comp) { create_competition }
        it 'calls the right action' do
          OrderRepository.stub(:find) { Order.build(payee_type: 'SanctioningBody', payer_id: uscs.kyck_id) }
          mc = mock_execute_action(KyckRegistrar::Actions::ApproveCards, { card_ids: [player1_card.kyck_id] },  [player1_card])
          mc.stub(:on)
          post :approve, competition_id: comp.kyck_id, card_ids: [player1_card.kyck_id], format: :json
        end
      end
    end

    describe '#decline' do
      let(:order) { Order.build(payee_type: 'SanctioningBody', payer_id: uscs.kyck_id) }
      before do
        OrderRepository.stub(:find) { order }
      end

      context 'for a competition' do

        let(:comp)  { create_competition }

        it 'calls the right action' do
          mc = mock_execute_action(KyckRegistrar::Actions::DeclineCards, { card_ids: [player1_card.kyck_id], reason: 'Bad avatars' },  [player1_card])
          mc.stub(:subscribe)
          mc.stub(:on)
          post :decline, competition_id: comp.kyck_id, card_ids: [player1_card.kyck_id], reason: 'Bad avatars', format: :json
        end
      end
    end
  end
end

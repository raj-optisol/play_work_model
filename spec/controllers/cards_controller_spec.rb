require 'spec_helper'

describe CardsController do
  include Devise::TestHelpers
  let(:requestor) { regular_user }
  let(:uscs) { create_sanctioning_body(name: 'USCS') }
  let(:club) { create_club }
  let(:player1) { regular_user }
  let(:player2) { regular_user }
  let(:staff) { regular_user }
  let(:player1_card ) { create_card(player1, club, uscs, order_id: '1234') }
  let(:player2_card ) { create_card(player2, club, uscs) }
  let(:staff_card ) { create_card(staff, club, uscs, kind: :staff) }
  let(:cards) { [player1_card, player2_card, staff_card] }
  let(:team) { create_team_for_organization(club) }
  let(:roster) { create_roster_for_team(team) }

  before(:each) do
    sign_in_user(requestor)
  end

  describe '#update' do
    context 'when saving a card update' do
      it 'redirects back to edit card' do
        stub_execute_action(KyckRegistrar::Actions::UpdateCard, { 'first_name' => 'Bill' }, player1_card)
        put :update, id: player1_card, card: { first_name: 'Bill' }, step: 'save'
        response.should redirect_to edit_card_path(player1_card)
      end
    end
  end

  describe '#index' do
    context 'for a sanctioning body' do
      it 'calls the right action' do
        mock_execute_action(
          KyckRegistrar::Actions::GetCards,
          {
            limit: 25,
            offset: 0,
            card_conditions: {}
          },
          cards
        )
        get :index, format: :json, sanctioning_body_id: uscs.kyck_id
        json.count.should == 3
      end

      it 'returns an alphabetized list of cards' do
        mock_execute_action(
          KyckRegistrar::Actions::GetCards,
          {
            limit: 25,
            offset: 0,
            card_conditions: {}
          },
          cards
        )
        get :index, format: :json, sanctioning_body_id: uscs.kyck_id
        names = json.each.map{ |c| "#{c['first_name']} #{c['last_name']}" }
        names.should == names.sort
      end

      context 'when filtering' do
        it 'filters the cards' do
          mock_execute_action(
            KyckRegistrar::Actions::GetCards,
            {
              limit: 25,
              offset: 0,
              card_conditions: { 'status' => 'approved' }
            },
            cards[0..1]
          )
          get :index, format: :json, sanctioning_body_id: uscs.kyck_id, filter: { status: 'approved' }
          json.count.should == 2
        end

        context 'for a team' do
          before do
            add_user_to_roster(roster, player1)
          end

           it 'returns the cards for just that team' do
             mock_execute_action(
               KyckRegistrar::Actions::GetCards,
               {
                 limit: 25,
                 offset: 0,
                 card_conditions: {},
                 team_conditions: { kyck_id: team.kyck_id }
               },
               [player2_card]
             )
             get :index, format: :json, team_id: team.kyck_id
           end
        end

        context 'for a sanction' do
          before do
            mock_execute_action(
              KyckRegistrar::Actions::GetCards,
              {
                limit: 25,
                offset: 0,
                card_conditions: {},
                sanction_conditions: { kyck_id: '12354' }
              },
              [player2_card]
            )
          end

          it 'filters the cards' do
             get :index, format: :json, filter: { sanction_id: '12354' }
          end
        end
      end
    end

    context 'for an organization' do
      before do
        mock_execute_action(
          KyckRegistrar::Actions::GetCards,
          {
            limit: 25,
            offset: 0,
            card_conditions: {},
            organization_conditions: { kyck_id: club.kyck_id }
          },
          [player2_card]
        )
      end

      it 'returns the cards for the organization' do
        get :index, format: :json, organization_id: club.kyck_id
      end
    end

    context 'by order' do
      let(:order) do
        Order.build(
          payee_type: 'SanctioningBody',
          payee_id: uscs.kyck_id,
          payer_type: 'Organization',
          payer_id: club.kyck_id
        )
      end

      it 'filters the cards' do
        OrderRepository.stub(:find) { order }
        mock_execute_action(
          KyckRegistrar::Actions::GetCards,
          {
            limit: 25,
            offset: 0,
            card_conditions: {
              'status' => 'approved',
              'order_id' => '1234'
            }
          },
          [cards[0]]
        )
        get :index, format: :json, card_request_id: '1234'
        json.count.should == 1
      end
    end
  end

  describe '#approve' do
    let(:order) do
      Order.build(
        payee_type: 'SanctioningBody',
        payee_id: uscs.kyck_id,
        payer_type: 'Organization',
        payer_id: club.kyck_id
      )
    end
    it 'calls the right action' do
      OrderRepository.stub(:find) { order }
      mc = mock_execute_action(KyckRegistrar::Actions::ApproveCards, { card_ids: [player1_card.kyck_id] }, [player1_card])
      mc.stub(:on)
      post :approve, card_request_id: '1234', card_ids: [player1_card.kyck_id], format: :json
    end

    context 'when an order_id is supplied' do
      it 'redirects to that order' do
        OrderRepository.stub(:find) { order }
        Order.any_instance.stub(:payee) { uscs }
        mc = mock_execute_action(KyckRegistrar::Actions::ApproveCards, { card_ids: [player1_card.kyck_id] }, [player1_card])
        mc.stub(:on)
        post :approve, card_request_id: '1234', card_ids: [player1_card.kyck_id]
        response.should redirect_to sanctioning_body_card_request_path(uscs, '1234')
      end
    end
  end

  describe '#decline' do
    let(:order) do
      Order.build(
        payee_type: 'SanctioningBody',
        payee_id: uscs.kyck_id,
        payer_type: 'Organization',
        payer_id: club.kyck_id
      )
    end
    before do
      OrderRepository.stub(:find) { order }
    end

    it 'calls the right action' do
      mc = mock_execute_action(KyckRegistrar::Actions::DeclineCards, { card_ids: [player1_card.kyck_id], reason: 'Bad avatars' },  [player1_card])
      mc.stub(:on)
      mc.stub(:subscribe)
      post :decline, card_request_id: '1234', card_ids: [player1_card.kyck_id], reason: 'Bad avatars', format: :json
    end
  end
end

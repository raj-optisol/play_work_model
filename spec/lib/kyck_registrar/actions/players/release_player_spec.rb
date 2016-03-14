# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe ReleasePlayer do
      let(:requestor) { regular_user }
      let(:org) { create_club }
      let(:team) { create_team_for_organization(org) }
      let(:roster) { create_roster_for_team(team) }
      let(:player) do
        p = org.add_player(
          regular_user(
            birthdate: 12.years.ago.to_date
          ),
          position: 'Goalkeeper',
          jersey_number: '10'
        )
        u = p.user
        roster.add_player(
          u,
          position: 'Goalkeeper',
          jersey_number: '10'
        )
        UserRepository.persist u
        Oriented.graph.commit
        p
      end

      describe '#initialize' do
        it 'takes a requestor, a club and a player id' do
          expect do
            described_class.new(requestor, org, player.kyck_id)
          end.not_to raise_error
        end
      end

      describe '#execute' do
        context 'when the user has permission' do
          subject { described_class.new requestor, org, player.kyck_id }

          before :each do
            add_user_to_org(requestor,
                            org,
                            title: 'Coach',
                            permission_sets: [PermissionSet::MANAGE_PLAYER])
          end

          it 'removes the player from the org and from any teams thereof' do
            subject.execute
            Oriented.graph.commit
            o = OrganizationRepository.find(kyck_id: org.kyck_id)
            r = TeamRepository::RosterRepository.find_by_attrs(
              conditions: { kyck_id: roster.kyck_id }
            ).first

            expect(o.players.count).to be_zero
            expect(r.players.count).to be_zero
          end

          context "when the user is on an order" do
            let(:sb) { create_sanctioning_body }
            let(:order) { create_order(requestor, org, sb, status: :new) }
            let(:card_product) {create_card_product(sb, age: 16, card_type: :player, amount: 18)}

            before do
              action = KyckRegistrar::Actions::AddOrderItem.new requestor, order, card_product, player.user
              action.execute
            end

            it "removes the order item" do
              expect {subject.execute}.to change {order._data.reload;order.order_items.count}.by(-1)
            end
          end

          it 'broadcasts the cards_released notification with a listing of ' \
            'all approved cards' do
            handler = double('handler')
            cards = double('cards')
            CardRepository.should_receive(:approved_player_for_user_and_org).with(
              instance_of(User),
              instance_of(Organization)).and_return(cards)
            handler.should_receive(:release_cards).with(
              cards,
              instance_of(User)
            )
            subject.subscribe(
              handler,
              on: :cards_released,
              with: :release_cards
            )
            subject.execute
          end

          it "adds a note to the card" do
            card = create_card(regular_user, org, create_sanctioning_body)
            CardRepository.stub(:new_for_user).and_return([card])
            expect { subject.execute }.to change {card.notes.count}.by(1) 
          end
        end
      end
    end
  end
end

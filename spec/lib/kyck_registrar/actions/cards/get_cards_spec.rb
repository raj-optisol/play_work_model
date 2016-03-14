require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetCards do

      let(:uscs) {create_sanctioning_body({name: 'USCS'})}
      let(:requestor) {regular_user}
      let(:club) {create_club}
      let(:player) {create_player_for_organization(club)}
      let(:uncarded_player) {create_player_for_organization(club)}
      let(:staff) { add_user_to_org(regular_user, club)}
      let(:team) {create_team_for_organization(club)}
      let(:roster) {create_team_for_organization(club)}
      let(:player_card) {uscs.card_user_for_organization(player.user, club)}
      let(:staff_card) {uscs.card_user_for_organization(staff.user, club, {kind: :staff})}

      let(:player2) {create_player_for_organization(club)}
      let(:player_card2) {uscs.card_user_for_organization(player2.user, club)}
      let(:staff2) { add_user_to_org(regular_user, club)}
      let(:staff_card2) {uscs.card_user_for_organization(staff2.user, club, {kind: :staff})}

      describe '#execute' do
        before do
          player_card
          staff_card
          add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
        end

        context 'for a sanctioning body' do
          subject{described_class.new(requestor, uscs)}

          it 'returns the cards' do
            cards = subject.execute({})
            cards.count.should == 2
          end

          context 'filtering' do
            context 'when current user can manage the card' do
              let(:current_user) { regular_user}

              before  do
                add_user_to_org(current_user, player_card.carded_for, permission_sets:[PermissionSet::PRINT_CARD])
              end

              it 'returns the cards' do
                act = described_class.new(current_user, uscs)
                cards = act.execute({card_conditions:{kyck_id: player_card.kyck_id}})
                cards.count.should == 1
                cards.first.kyck_id.should == player_card.kyck_id

              end
            end
          end
        end

        context 'for a club' do
          subject{described_class.new(requestor, uscs, club)}

          before do
            add_user_to_org(requestor, club, permission_sets: [PermissionSet::PRINT_CARD])
            player_card
            staff_card
          end

          it 'returns carded players' do
            cards = subject.execute({})
            card_ids = cards.map(&:kyck_id)
            card_ids.should include(player_card.kyck_id)
            cards.count.should == 2
          end

          it 'returns carded staff' do
            cards = subject.execute({})
            card_ids = cards.map(&:kyck_id)
            card_ids.should include(staff_card.kyck_id)
            cards.count.should == 2
          end

          context 'when filtering' do
            let(:team) { create_team_for_organization(club)}
            let(:roster) { create_roster_for_team(team)}
            let(:player2) {add_player_to_roster(roster)}
            let(:player2_card) { uscs.card_user_for_organization(player2.user, club, {status: :in_error})}

            let(:staff2) {add_user_to_org(regular_user, club)}
            let(:staff2_card) { uscs.card_user_for_organization(staff2.user, club, {kind: :staff})}

            before do
              player2_card
              staff2_card
              Oriented.graph.commit # Need to commit it since the getting of cards is using sql now for speed
            end

            context 'by user name' do
              it 'returns the right cards' do
                cards = subject.execute({user_conditions: { last_name: player2.user.last_name}})
                cards.count.should == 1
                cards.first.kyck_id.should == player2_card.kyck_id
              end

              it 'when the name has an apostrophe' do
                player_card2.last_name='O\'Brien'
                player_card2._data.save!
                cards = subject.execute({user_conditions: { last_name: player_card2.last_name}})
                cards.count.should == 1
                cards.first.last_name == 'O\'Brien'
              end
            end

            context 'by team' do
              it 'returns the right cards' do
                cards = subject.execute(team_conditions: { kyck_id: team.kyck_id})
                cards.count.should == 1
                cards.first.kyck_id.should == player2_card.kyck_id
              end
            end

            context 'by card type' do
              it 'returns the right cards' do
                cards = subject.execute({card_conditions: { kind: 'staff'}})
                cards.count.should == 2
                card_ids = cards.map(&:kyck_id)
                card_ids.should include(staff_card.kyck_id)
                card_ids.should include(staff2_card.kyck_id)
                card_ids.should_not include(player_card.kyck_id)
              end
            end

            context 'by status type' do
              it 'returns the right cards' do
                cards = subject.execute({card_conditions: { status: 'in_error'}})
                cards.count.should == 1
                cards.first.kyck_id.should == player2_card.kyck_id
              end
            end
          end # when filtering

          context 'for an order' do
            let(:order) { create_order(requestor, club, uscs, kind: :card_request ) }
            let(:player_cp) { create_card_product(uscs, card_type: :player) }
            let(:staff_cp) { create_card_product(uscssb, card_type: :staff) }
            let!(:player_order_item) do

              order_item_attributes = {
                product_for_obj_id: player.kyck_id,
                product_for_obj_type: 'User',
                amount: 20.0,
                product_id: player_cp.id,
                product_type: 'CardProduct',
                description: 'Card',
                item_type: 'Card',
                item_id: player_card.kyck_id
              }

              oi = order.add_order_item(order_item_attributes)
              order._data.save
              oi
            end
            let(:input) { { card_conditions: { order_id: order.id } } }

            it 'returns the cards for the order' do
              cards = subject.execute(input)
              assert_equal cards.first.kyck_id, player_card.kyck_id
            end
          end
        end
      end  # END CLUB
    end
  end
end

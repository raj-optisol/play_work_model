# encoding: UTF-8
require 'spec_helper'

describe CardOrderFixer do
  let(:user) { regular_user }
  let(:club) { create_club }
  let(:uscs) { create_sanctioning_body }

  describe '#fix_order' do
    subject(:fixer) { described_class.new }

    context 'when order is not fixable' do
      let(:order) { create_order(user, club, uscs, status: :submitted) }
      context 'when order status is new' do
        it 'should return an error status' do
          order.status = :new
          result = fixer.fix_order(order)
          expect(result[:status]).to eq('error')
        end
      end

      context 'when order status is pending payment' do
        it 'should return an error status' do
          order.status = :pending_payment
          result = fixer.fix_order(order)
          expect(result[:status]).to eq('error')
        end
      end

      context 'when order is not a card request' do
        it 'should return an error status' do
          order.kind = :deposit
          result = fixer.fix_order(order)
          expect(result[:status]).to eq('error')
        end
      end

      context 'when order is missing its organization' do
        it 'should return an error status' do
          order.payer_id = 'fake_kyck_id'
          result = fixer.fix_order(order)
          expect(result[:status]).to eq('error')
        end
      end
    end

    context 'when order is fixable' do
      let(:order) { create_order(user, club, uscs, status: :submitted) }
      it 'should call fix_item for each item in the order' do
        (0..3).each { order.add_order_item(order_item_hash) }
        count = order.order_items.count

        expect(fixer).to receive(:fix_item).exactly(count).times
        fixer.fix_order(order)
      end

      it 'should call the OrderHandler handle_card_order_status method' do
        # I wanted to follow the "expect" syntax here but I wasn't able
        # to figure out why it wouldn't work with it.
        OrderHandler.any_instance.should_receive(:handle_card_order_status)
        fixer.fix_order(order)
      end

      it 'should return a success status' do
        result = fixer.fix_order(order)
        expect(result[:status]).to eq('success')
      end
    end

    context 'when order is busted' do
      let!(:product) { create_card_product(uscs) }
      let!(:player1) { regular_user }
      let!(:player2) { regular_user }
      let!(:staff1) { regular_user }

      let(:order) do
        odr = create_order(user, club, uscs, status: :submitted)
        odr.submitted_on = Date.today
        odr
      end

      let!(:item1) do
        itm = order.add_order_item(order_item_hash)
        itm.product_for_obj_id = player1.kyck_id
        itm.product_for_obj_type = 'User'
        itm.product_id = product.id
        itm.product_type = 'CardProduct'
        itm
      end

      let!(:item2) do
        itm = order.add_order_item(order_item_hash)
        itm.product_for_obj_id = player2.kyck_id
        itm.product_for_obj_type = 'User'
        itm.product_id = product.id
        itm.product_type = 'CardProduct'
        itm
      end

      let!(:item3) do
        itm = order.add_order_item(order_item_hash)
        itm.product_for_obj_id = staff1.kyck_id
        itm.product_for_obj_type = 'User'
        itm.product_id = product.id
        itm.product_type = 'CardProduct'
        itm
      end

      context 'when order is submitted but some cards are processed' do
        let!(:card1) { create_card(player1, club, uscs) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should change the order status to in progress' do
          item1.status = 'processed'
          fixer.fix_order(order)

          expect(order.status).to eq(:in_progress)
        end
      end

      context 'when order is submitted but all cards are processed' do
        let!(:card1) { create_card(player1, club, uscs) }
        let!(:card2) { create_card(player2, club, uscs) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should change the order status to completed' do
          item2.status = 'processed'
          fixer.fix_order(order)

          expect(order.status).to eq(:completed)
        end
      end

      context 'when order is in progress but no cards are processed' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs, status: :new) }

        it 'should change the order status to submitted' do
          order.status = :in_progress
          fixer.fix_order(order)

          expect(order.status).to eq(:submitted)
        end
      end

      context 'when order is in progress but all cards are processed' do
        let!(:card1) { create_card(player1, club, uscs) }
        let!(:card2) { create_card(player2, club, uscs) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should change the order status to completed' do
          order.status = :in_progress
          fixer.fix_order(order)

          expect(order.status).to eq(:completed)
        end
      end

      context 'when order is completed but no cards are processed' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs, status: :new) }

        it 'should change the order status to submitted' do
          order.status = :completed
          fixer.fix_order(order)

          expect(order.status).to eq(:submitted)
        end
      end

      context 'when order is completed but some cards are not processed' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should change the order status to in progress' do
          order.status = :completed
          fixer.fix_order(order)

          expect(order.status).to eq(:in_progress)
        end
      end

      context 'when order has an incorrect pending count' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should update the item counts correctly' do
          order.status = :in_progress
          order._data.pending_item_count = 0
          fixer.fix_order(order)

          expect(order.pending_item_count).to eq(2)
        end
      end

      context 'when order item is processed and card is still new' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }
        let!(:card3) { create_card(staff1, club, uscs) }

        it 'should update the item status correctly' do
          item1.status = 'processed'
          fixer.fix_order(order)

          expect(item1.status.to_sym).to eq(:new)
        end

        it 'should update the order status correctly' do
          order.status = :completed
          item1.status = 'processed'
          item2.status = 'processed'
          item3.status = 'processed'

          fixer.fix_order(order)

          expect(order.status).to eq(:in_progress)
        end
      end

      context 'when order item has no existing card' do
        let!(:card1) { create_card(player1, club, uscs, status: :new) }
        let!(:card2) { create_card(player2, club, uscs, status: :new) }

        it 'should create one for it' do
          item3.status = 'new'
          fixer.fix_order(order)

          expect(item3.item_id).not_to be_nil
        end
      end
    end
  end
end

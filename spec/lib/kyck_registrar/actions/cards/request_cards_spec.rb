# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RequestCards do
      before do
        fixer = double
        fixer.stub(:run)

        CardOrderFixer.stub(:new).and_return(fixer)
        CardApprovalEmailHandler.any_instance.stub(:add_to_queue)
      end

      let(:requestor) { regular_user }
      let(:club) { create_club }
      let(:sb) { create_sanctioning_body }
      let(:player) { regular_user }
      let(:player_cp) { create_card_product(sb, card_type: :player) }
      let(:staff_cp) { create_card_product(sb, card_type: :staff) }
      let(:player) { regular_user }
      let(:staff) { regular_user }
      let(:order) { create_order(requestor, club, sb) }
      let(:notifier) { Object.new }
      let(:player_order_item) do

        order_item_attributes = {
          product_for_obj_id: player.kyck_id,
          product_for_obj_type: 'User',
          amount: 20.0,
          product_id: player_cp.id,
          product_type: 'CardProduct',
          description: 'Card'
        }

        oi = order.add_order_item(order_item_attributes)
        order._data.save
        oi
      end
      
      let(:staff_order_item) do

        order_item_attributes = {
          product_for_obj_id: staff.kyck_id,
          product_for_obj_type: 'User',
          amount: 20.0,
          product_id: staff_cp.id,
          product_type: 'CardProduct',
          description: 'Card'
        }

        oi = order.add_order_item(order_item_attributes)
        order._data.save
        oi
      end

      let(:items) do
        {items: [
          player_order_item
        ]}.with_indifferent_access
      end

      before do
        notifier.stub(:staff_card_created)
      end

      describe '#execute' do
        subject { described_class.new(requestor, club, sb) }

        before do
          add_user_to_org(requestor, club, permission_sets: [PermissionSet::REQUEST_CARD])
        end

        context 'when a card does not exist for the user and org' do
          let(:input) { { items: [player_order_item] } }

          it 'creates a card' do
            expect do
              subject.execute(input)
              Oriented.graph.commit
              player._data.reload
            end.to(
              change { player.cards.count }.by(1)
            )
          end

          it 'sets the expiration to Aug 1' do
            c = subject.execute(input)
            time = Time.at(c.first.expires_on)
            assert_equal time.month, 8
            assert_equal time.day, 1
          end

          it 'generates the card duplicate lookup hash' do
            c = subject.execute(input).first
            c.duplicate_lookup_hash.should == Digest::MD5.hexdigest([c.first_name.downcase, c.last_name.downcase, c.birthdate].join)
          end

          context 'on July 1' do
            before do
              new_time = Time.local(2014, 7, 2, 2, 0, 0)
              Timecop.freeze(new_time)
            end

            after do
              Timecop.return
            end

            it 'sets the expiration to Aug 1 the following year' do
              c = subject.execute(input)
              time = Time.at(c.first.expires_on)
              assert_equal time.month, 8
              assert_equal time.day, 1
              assert_equal time.year, Time.now.year + 1
            end
          end

          it 'creates staff cards for staff' do
            subject.execute(items: [staff_order_item])
            staff.cards.first.kind.should == :staff
          end

          it 'sends an email to staff' do
            notifier.should_receive(:staff_card_created).once
            subject.notifier = notifier
            subject.execute(items: [staff_order_item])
          end

          it 'calls the card email handler' do
            CardApprovalEmailHandler.any_instance.should_receive(:add_to_queue)
            subject.notifier = notifier
            subject.execute(items: [staff_order_item])
          end

          context 'user attributes' do
            let(:cards) { subject.execute(input) }

            context 'when the user does not have a previous card' do
              it 'copies the name attributes from the user to the card' do
                c = cards.first
                c.first_name.should == player.first_name
                c.last_name.should == player.last_name
                c.middle_name.should == player.middle_name
              end

              it 'copies the birthdate from the user' do
                c = cards.first
                c.birthdate.should == player.birthdate
              end
            end
          end

          context 'when an order is supplied' do
            subject do
              action = described_class.new(requestor, club, sb)
              action.notifier = notifier
              items[:order_id] = order.id
              action.execute(items)
            end

            it 'sets the card id on the order item'  do
              cards = subject

              assert_equal player_order_item.item_id.to_s, cards.first.kyck_id
              assert_equal player_order_item.item_type, 'Card'
            end

            it 'sets the amount on the card'  do
              subject
              player._data.reload
              player.cards.first.amount_paid.should == player_order_item.amount.to_f
            end
          end
        end

        context 'when an order_item has a competition id' do
          let(:comp) { create_competition }
          let(:items) { {items: [player_order_item] } }

          before do
            items[:items][0].competition_id = comp.kyck_id
          end

          it 'adds a processor to the card' do
            subject.execute(items)
            Oriented.graph.commit
            player._data.reload
            player.cards.first.processor.should_not be_nil
            player.cards.first.processor.kyck_id.should == comp.kyck_id
          end
        end

        context 'when the user has a card for the org' do
          let!(:card) { create_card(player, club, sb) }
          let(:items) { {items: [player_order_item] } }

          it 'does not create a new card' do
            cards = subject.execute(items)
            assert_equal cards.first.kyck_id, card.kyck_id
          end
        end

        context 'when there is a duplicate card' do
          let(:other_club) { create_club }
          let!(:card) { create_card(player, other_club, sb) }
          let(:items) { {items: [player_order_item] } }

          it 'marks the card as a dup' do
            cards = subject.execute(items)
            assert cards.first.has_duplicates
          end

          context 'but the cards is released' do
            before do
              card.status ='released'
            end

            it 'does not mark the card as a dup' do
              cards = subject.execute(items)
              assert cards.first.has_duplicates
            end
          end
        end
      end
    end
  end
end

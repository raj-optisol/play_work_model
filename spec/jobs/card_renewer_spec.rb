require 'spec_helper'

module Jobs
  describe CardRenewer, broken: true do

    let(:issuer)  { regular_user }
    let(:club)    { create_club }
    let(:clubD)   { create_club }
    let(:sb)      { create_sanctioning_body }
    let(:player)  { regular_user({ birthdate: 15.years.ago }) }
    let(:playerD) { regular_user({ birthdate: 12.years.ago }) }


    let(:card_product)    { create_card_product(sb, card_type: :player) }
    let!(:previous_card)  { create_card(player, club, sb, { status: :expired, expires_on: 2.days.ago.to_i }) }
    let!(:duplicate_card) { create_card(playerD, club, sb, { status: :active, expires_on: (Time.now + 2.days).to_i, duplicate_lookup_hash: 'imaduplicate' }) }


    subject { described_class.new }


    describe "#execute" do

      context "for cards" do
        let(:order) { create_order(issuer, club, sb, status: :submitted, payment_status: :authorized) }

        context "when card is a renewal" do
          let!(:card) { create_card(player, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i }) }

          it "sets the card status to approved" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.status.should == :approved
          end

          it "sets the approved on date to the current date" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.approved_on.should be_between((Time.now - 1.day).to_i, (Time.now + 1.day).to_i)
          end

          it "sets the is renewal flag to true" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.is_renewal.should == true
          end

          it "sets the has duplicates flag to false" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.has_duplicates.should == false
          end
        end



        context "when card is a duplicate" do
          let!(:card) { create_card(playerD, clubD, sb, { status: :new, duplicate_lookup_hash: 'imaduplicate', order_id: order.id, expires_on: (Time.now + 2.days).to_i }) }

          it "sets the card status to new" do
            subject.process(order.id)
            card._data.reload

            card.status.should == :new
          end

          it "sets the approved on date to nil" do
            subject.process(order.id)
            card._data.reload

            card.approved_on.should be_nil
          end

          it "sets the is renewal flag to false" do
            subject.process(order.id)
            card._data.reload

            card.is_renewal.should == false
          end

          it "sets the has duplicates flag to true" do
            subject.process(order.id)
            card._data.reload

            card.has_duplicates.should == true
          end
        end


        context "when card is a duplicate and renewal" do
          let(:card) { create_card(player, club, sb, { status: :new, duplicate_lookup_hash: 'imaduplicate', order_id: order.id, expires_on: (Time.now + 2.days).to_i }) }

          it "sets the card status to new" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.status.should == :new
          end

          it "sets the approved on date to nil" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.approved_on.should be_nil
          end

          it "sets the renewal flag to true" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.is_renewal.should == true
          end

          it "sets the has duplicates flag to true" do
            card._data.previous = previous_card._data
            card._data.save
            subject.process(order.id)
            card._data.reload

            card.has_duplicates.should == true
          end
        end
      end



      context "for orders" do
        let(:order) { create_order(issuer, club, sb, status: :submitted, payment_status: :authorized) }

        context "when all cards have been approved" do
          it "sets the order status to completed" do
            card1 = create_card(player, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            card2 = create_card(playerD, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            card1._data.previous = card2._data.previous = previous_card._data
            card1._data.save
            card2._data.save
            subject.process(order.id)
            order._data.reload

            order.status.should == :completed
          end
        end

        context "when some cards have been approved" do
          it "sets the order status to in progress" do
            card1 = create_card(player, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            card2 = create_card(playerD, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            card1._data.previous = previous_card._data
            card1._data.save
            subject.process(order.id)
            order._data.reload

            order.status.should == :in_progress
          end
        end

        context "when no cards have been approved" do
          it "sets the order status to submitted" do
            card1 = create_card(player, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            card2 = create_card(playerD, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i })
            subject.process(order.id)
            order._data.reload

            order.status.should == :submitted
          end
        end
      end



      # context "when an error happens" do
      #   let(:order) { create_order(issuer, club, sb, status: :submitted, payment_status: :authorized) }
      #   let(:card) { create_card(player, club, sb, { status: :new, order_id: order.id, expires_on: (Time.now + 2.days).to_i }) }
      #
      #   it "sends it to Raven" do
      #     CardRepository.stub(:find_by_attrs_sql).and_raise(Exception)
      #     Raven.should_receive(:capture_exception)
      #     subject.process(1)
      #   end
      # end

    end
  end
end

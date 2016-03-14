require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateCards, broken: true do
      let(:uscs) {create_sanctioning_body(name: 'USCS')}
      let(:club) {create_club}
      let(:requestor) {regular_user}
      let(:cp1) {create_card_product(uscs, card_type: :player)}
      let(:cp2) {create_card_product(uscs, card_type: :staff)}
      let(:player1) { regular_user({birthdate: 8.years.ago, avatar:'1234', avatar_version:'12322', avatar_uri:'http://gravatar.com/image.png'})}
      let(:player2) { regular_user({birthdate: 6.years.ago})}
      let(:player3) { regular_user({birthdate: 8.years.ago, avatar: 'user_avatar_syy1gy'}) }
      let(:staff) { regular_user}
      let(:notifier) { Object.new}

      before do
        notifier.stub(:staff_card_created)
      end

      describe "#execute" do
        let(:items) {
          {items: [
            create_item(player1),
            create_item(player2),
            create_item(staff, :staff)
          ]}.with_indifferent_access
        }
        subject {

          c = described_class.new(requestor, club, uscs)
          c.notifier = notifier
          c
        }

        context "when the user has permission" do
          before do
            add_user_to_org(requestor, club, permission_sets: [PermissionSet::REQUEST_CARD])
          end

          it "creates cards for the items" do
            expect {
              subject.execute(items)
            }.to change { CardRepository.all.count }.by(3)
          end

          it "creates player cards for players" do
            subject.execute(items)
            player1._data.reload
            player2._data.reload
            player1.cards.first.kind.should == :player
            player2.cards.first.kind.should == :player
          end

          it "creates staff cards for staff" do
            subject.execute(items)
            staff.cards.first.kind.should == :staff
          end

          it "sends an email to staff" do
            notifier.should_receive(:staff_card_created).once
            subject.execute(items)
          end

          it "marks approval email sent as false" do
            cards = subject.execute(items)
            cards.first.approval_email_sent.should_not be_nil
            cards.first.approval_email_sent.should be_false
          end

          context "user attributes" do
            let(:cards) {subject.execute(items)}

            context "when the user does not have a previous card" do
              it "copies the name attributes from the user to the card" do
                c = cards.first
                c.first_name.should == c.carded_user.first_name
                c.last_name.should == c.carded_user.last_name
                c.middle_name.should == c.carded_user.middle_name
              end

              it "copies the birthdate from the user" do
                c = cards.first
                c.birthdate.should == c.carded_user.birthdate
              end

              context "when the user has a proof of birth", broken:true  do

                let!(:pob) { create_document_for_user(player1, {kind: :proof_of_birth})}

                it "links to that users's proof of birth" do
                  c = cards.first
                  player1.cards.first.documents.map(&:kyck_id).should include(pob.kyck_id)
                end
              end
            end


            context "when the user has a previous card" do
              let!(:previous_card) {create_card(player1, club, uscs, {first_name: 'Jonathan', middle_name: nil, status: :expired, expires_on: 2.days.ago.to_i}.with_indifferent_access)}
              it "copies the attributes from the previous card" do
                c = cards.first
                player1.cards.first.first_name.should == 'Jonathan'
              end

              it "copies attributes from the user if previous card doesn't have a value for it" do
                previous_card.stub(:middle_name) {nil}
                c = cards.first
                previous_card.middle_name.should be_nil
                player1.middle_name.should_not be_nil
                c.middle_name.should == player1.middle_name
              end

            end
          end

          context "when an order_item has a competition id" do
            let(:comp) {create_competition}
            before do
              items[:items][1].competition_id = comp.kyck_id
            end

            it "adds a processor to the card" do
              subject.execute(items)
              Oriented.graph.commit
              player2._data.reload
              player2.cards.first.processor.should_not be_nil
              player2.cards.first.processor.kyck_id.should == comp.kyck_id
            end
          end


          it "sets the default expires on to August 1" do
            Timecop.freeze do
              subject.execute(items)
              player1._data.reload
              player1.cards.first.expires_on.should == Time.parse("2014-08-01 00:00:00").to_i
            end
          end

          context "when today is July 2" do
            before do
              new_time = Time.local(2014, 7, 2, 2, 0, 0)
              Timecop.freeze(new_time)
            end

            after do
              Timecop.return
            end

            it "sets the default expires to August 1 of following year" do
              subject.execute(items)
              player1._data.reload
              player1.cards.first.expires_on.should == Time.parse("2015-08-01 00:00:00").to_i
            end
          end

          it "generates the card duplicate lookup hash" do
            c = subject.execute(items).first
            c.duplicate_lookup_hash.should == Digest::MD5.hexdigest([c.first_name.downcase, c.last_name.downcase, c.birthdate].join)
          end

          context "when a user is already carded" do
            let(:conditions) {
              {
                user_conditions: {
                  kyck_id: player1.kyck_id
                },
                card_conditions: {
                  status_in: ["approved", "new", "requestor_response_required", "requestor_response_received"]
                }
              }
            }
            before do
              @existing_card = create_card(player1, club, uscs, {kind: 'player', status: :approved, expires_on: 2.months.from_now.to_i})
            end

            it "does not create another card" do
              subject.execute(items)
              player1.cards.count.should == 1
            end


          end

          context "and the card is inactive" do
            before  do
              @existing_card = create_card(player1, club, uscs, {kind: 'player', status: :expired, expires_on: 2.days.ago.to_i})
            end

            it "creates a new card" do
              expect {
                subject.execute(items)
                Oriented.graph.commit

              }.to change {CardRepository.count}.by(3)
            end

            it "links the existing card to the new card" do
              subject.execute(items)
              @existing_card._data.reload
              @existing_card.next.should_not be_nil
            end

            it "links the new card to the existing card" do
              subject.execute(items)
              @existing_card._data.reload
              new_card = @existing_card.next
              new_card.previous.kyck_id.should == @existing_card.kyck_id
            end

            it "removes the relationship from the old card to the sb" do
              subject.execute(items)
              @existing_card._data.reload
              @existing_card.sanctioning_body.should be_nil
            end

            it "removes the relationship from the old org to the card" do
              subject.execute(items)
              @existing_card._data.reload
              @existing_card.carded_for.should be_nil
            end

            context "when the card has a processor" do
              let(:comp) {create_competition}
              before do
                @existing_card._data.processor =comp._data
                @existing_card._data.save
              end

              it "removes the relationship to the old procesor" do
                @existing_card.processor.should_not be_nil
                subject.execute(items)
                @existing_card._data.reload
                @existing_card.processor.should be_nil
              end

            end


          end
          context "when an order is supplied" do
            subject {
              action = described_class.new(requestor, club, uscs)
              action.notifier = notifier
              items[:order_id] = "1235"
              action.execute(items)
            }

            it "sets the order on the card"  do
              subject
              player1._data.reload
              player1.cards.first.order_id.should == "1235"
            end

            it "sets the order_item on the card"  do
              subject
              player1._data.reload
              player1.cards.first.order_item_id.should == "4567"
            end

            it "sets the amount on the card"  do
              subject
              player1._data.reload
              player1.cards.first.amount_paid.should == 15.0
            end

          end
        end

        context "when the user does not have permission" do

          it "raises a PermissionsError" do
            expect{subject.execute(items)
            }.to raise_error PermissionsError
          end

        end
      end

      def create_item(user, card_type = :player, attrs ={})
        cp = card_type == :player ? cp1 : cp2
        card_attrs = { product_id: cp.id, product_type: cp.class.to_s, product_for_obj_id: user.kyck_id, product_for_obj_type: user.class.to_s, id: '4567', amount: '15.0' }.merge(attrs)
        OpenStruct.new(card_attrs)
      end
    end
  end
end

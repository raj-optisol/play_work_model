require 'spec_helper'

module KyckRegistrar
  module Actions
    describe AddOrderItem do

      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a order" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end

        it "takes a product" do
          expect{described_class.new(User.new, Order.new)}.to raise_error ArgumentError
        end

        it "can take a for_obj" do
          expect{described_class.new(User.new, Order.new, CardProduct.new, Organization.new)}.to_not raise_error ArgumentError
        end
      end

      describe "#execute" do
        let(:requestor) { regular_user }
        let(:sb) { create_sanctioning_body }
        let(:org) { create_club }
        let(:order) {
          create_order(requestor, org, sb, {kind: :sanctioning_request, amount: 0.0})
        }
        let(:srp) {
          attrs = {:kind => 'competition', :amount=>1000.0, :sanctioning_body_id => sb.kyck_id}
          req = SanctioningRequestProduct.build(attrs)
          SanctioningRequestProductRepository.persist req
        }

        context 'creating and adding order item to order' do
          it 'should create a new order item' do
            result = described_class.new(requestor, order, srp).execute({})
            result.id.should == order.id
            order.order_items.count.should == 1

            order.amount.should == result.amount
          end


        end
        context 'when adding player cards' do
          let(:kid) {regular_user(avatar: 'not_default.png')}
          let(:card_product) {create_card_product(sb, age: 16, card_type: :player, amount: 18)}
          let(:order) {
            create_order(requestor, org, sb, {kind: :card_request, amount: 0.0})
          }

          before(:each) do
            add_user_to_org(requestor, org, permission_sets: [PermissionSet::REQUEST_PLAYER_CARD])
            @player = org.add_player(kid, {:gender=>"male"})
            OrganizationRepository.persist org
            Oriented.graph.commit

            @order = Order.build(:initiator_id=>requestor.kyck_id, :amount=>0, :status=>:new, :payer_type => "Organization", :payer_id=>org.id, kind: :card_request)
            OrderRepository.persist! @order

            [:waiver, :proof_of_birth].each do |k|
              d = kid.create_document(title: k, kind: k)
              DocumentRepository.persist d
            end

          end

          subject { action = KyckRegistrar::Actions::AddOrderItem.new requestor, @order, card_product, kid}

          it 'adds the item to the order' do
              input = {}
              expect { subject.execute input}.to change{@order.order_items.count}.by(1)
          end

          it 'does not allow duplicates' do
            input = { }
            result = subject.execute input

            expect {
              result = subject.execute input
            }.to change {
              @order.order_items.count
            }.by(0)
          end

          context "when adding a 2nd item" do
            let(:kid2) {regular_user(avatar: 'not_default.png')}

            before(:each) do
              [:waiver, :proof_of_birth].each do |k|
                d = kid2.create_document(title: k, kind: k)
                DocumentRepository.persist d
              end

              action = KyckRegistrar::Actions::AddOrderItem.new requestor, @order, card_product, kid2
              action.execute
            end

            it "has the right amount" do
              input = {}
              subject.execute(input)
              @order.amount.to_f.should == 36.0
            end

            it "has 2" do
              input = {}
              expect {subject.execute(input)}.to change {@order.order_items.count}.by(1)
            end

          end

          context "when the user is not ready for a card" do

            it "doesn't add the item" do
              kid.avatar = nil
              obj = Object.new
              obj.stub(:valid?) {false}
              expect {subject.execute({}, obj)}.to raise_error ArgumentError
            end

          end

          context "when a competition id is supplied" do
            let(:comp) { create_competition }

            it "puts the competition_id on the order item" do
              result = subject.execute( {competition_id: comp.kyck_id} )
              result.competition_id.to_s.should == comp.kyck_id
            end

          end
        end
      end
    end
  end
end



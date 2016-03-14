require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveOrderItem do

      describe "#execute" do
        context "for card products" do
          let(:requestor) { regular_user }
          let(:sb) { create_sanctioning_body }
          let(:org) { create_club }
          let(:order) {
            attrs = {initiator_id: requestor.kyck_id, payer_id: org.kyck_id, payer_type: org.class.to_s, payee_id: sb.kyck_id, payee_type: sb.class.to_s, kind: 'card_request', amount: 0.0}
            order = Order.build(attrs)
            OrderRepository.persist order
          }
          let(:kid1) {regular_user(avatar: "avatar.png")}
          let(:kid2) {regular_user(avatar: "avatar.png")}
          let(:kid3) {regular_user(avatar: "avatar.png")}
          let(:season) {create_season_for_organization(org)}
          let(:card_product) {create_card_product(sb, age: 16, card_type: :player, amount: 18)}

          before do
            [:waiver, :proof_of_birth].each do |k|
              d = kid1.create_document(title: k, kind: k)
              DocumentRepository.persist d
            end
            [:waiver, :proof_of_birth].each do |k|
              d = kid2.create_document(title: k, kind: k)
              DocumentRepository.persist d
            end
            [:waiver, :proof_of_birth].each do |k|
              d = kid3.create_document(title: k, kind: k)
              DocumentRepository.persist d
            end
            input = {}
            action = KyckRegistrar::Actions::AddOrderItem.new requestor, order, card_product, kid1
            action.execute input
            action = KyckRegistrar::Actions::AddOrderItem.new requestor, order, card_product, kid2
            action.execute input
            action = KyckRegistrar::Actions::AddOrderItem.new requestor, order, card_product, kid3
            action.execute input
          end

          subject { described_class.new(requestor, order).execute({id: order.order_items.first.id})}

          it "removes the item" do
            expect {subject}.to change {order._data.reload;order.order_items.count}.by(-1)
          end

          it "updates the order amount" do
            subject
            order._data.reload.amount.to_f.should == 36
          end

          context "when the delete fails" do

            before do
              OrderRepository::OrderItemRepository.stub(:delete) {false}
            end
            it "doesn't update the amount" do
              expect {subject}.to raise_error
              order._data.reload.amount.should_not == 0.0
            end

          end
        end
      end
    end
  end
end

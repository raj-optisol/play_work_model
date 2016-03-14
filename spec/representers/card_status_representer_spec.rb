# encoding: UTF-8
# Card status representer tests.
require_relative '../../app/representers/card_status_representer'

describe CardStatusRepresenter do
  subject { OpenStruct.new.extend(CardStatusRepresenter) }

  let(:user) { regular_user }
  let!(:uscs) { create_sanctioning_body(name: 'USCS') }
  let(:club) { create_club }
  let(:order) { create_order(user, club, uscs) }
  let(:cp) { create_card_product(uscs) }

  context 'When the user has no card' do
    it 'returns \'Not Requested\' as the status' do
      subject.user = user
      latest_order = create_order(user, club, uscs)
      subject.card_status(latest_order).should == 'Not Requested'
    end

    context 'when the user has a waiver' do
      before do
        subject.user = user
        @doc = create_document_for_user(user, kind: :waiver)
      end

      it('includes it') do
        JSON.parse(subject.to_json)["waiver"]["id"].should == @doc.kyck_id
      end
    end

    context 'when the user has a POB' do
      before do
        subject.user = user
        @doc = create_document_for_user(user, kind: :proof_of_birth)
      end

      it('includes it') do
        JSON.parse(subject.to_json)["proof_of_birth"]["id"].should == @doc.kyck_id
      end
    end
  end

  context 'When the user has an existing card' do
    it 'returns \'In Cart\' as the status' do
      subject.user = user
      subject.card_type = :player
      order.add_order_item(
        product_for_obj_id: user.kyck_id,
        product_for_obj_type: 'User',
        amount: 15,
        product_id: cp.id,
        product_type: 'CardProductData',
        description: 'Card for User'
      )

      subject.card_status(order).should == 'In Cart'
    end

    context 'When the card status is new or approved' do
      it 'returns the expiration countdown for new' do
        exps = (Time.now + 7.days).to_i
        create_card(user, club, uscs, status: :new, expires_on: exps)

        subject.user = user
        subject.card_type = :player
        subject.card_status(order).should =~ /Expire/
      end

      it 'returns the expiration countdown for approved' do
        exps = (Time.now + 1.days).to_i
        create_card(user, club, uscs, status: :approved, expires_on: exps)

        subject.user = user
        subject.card_type = :player
        subject.card_status(order).should == 'Expires in 1 day'
      end

      it 'returns expired' do
        exps = (Time.now - 7.days).to_i
        create_card(user, club, uscs, status: :new, expires_on: exps)

        subject.user = user
        subject.card_type = :player
        subject.card_status(order).should == 'Expired'
      end
    end

    it 'returns the card status' do
      exps = (Time.now + 7.days).to_i
      create_card(user, club, uscs, status: :inactive, expires_on: exps)

      subject.user = user
      subject.card_type = :player
      subject.card_status(order).should == 'Inactive'
    end
  end
end

# encoding: UTF-8
require 'spec_helper'

describe KyckRegistrar::Actions::GetOrCreateOrder do
  let(:requestor) { regular_user }
  let!(:uscs) { create_sanctioning_body }
  let(:club) { create_club }
  let(:admin) { admin_user }
  subject { described_class.new(requestor) }

  it 'creates a new order for user' do
    expect do
      subject.execute(payer_id: club.kyck_id,
                      payer_type: 'Organization',
                      state: 'NC')
      Oriented.graph.commit
    end.to change { OrderRepository.all.count }.by(1)
  end

  context 'when payer/payee attributes are passed in' do
    let(:pay_attributes) do
      {
        payer_id: club.kyck_id,
        payer_type: 'Organization',
        payee_id: uscs.kyck_id,
        payee_type: 'SanctioningBody',
        state: 'NC'
      }
    end

    it 'puts those on the order' do
      result = subject.execute(pay_attributes)
      result.payee_type.should == pay_attributes[:payee_type]
      result.payee_id.should.to_s == pay_attributes[:payee_id]
      result.payer_type.should == pay_attributes[:payer_type]
      result.payer_id.should.to_s == pay_attributes[:payer_id]
      result.state.should == 'NC'
    end

    it 'sets assigned_kyck_id and assigned_name fields on a new order' do
      OrganizationRepository.stub(find_by_kyck_id: club)
      club.stub(uscs_admin: admin)
      result = subject.execute(pay_attributes)
      result.assigned_kyck_id.to_s.should == admin.kyck_id.to_s
      result.assigned_name.should == admin.full_name
    end

    it 'sets default assigned fields' do
      result = subject.execute(pay_attributes)
      assert_equal(result.assigned_kyck_id.to_s,
                   '00000000-0000-0000-0000-000000000000')
      result.assigned_name.should == 'Not Assigned'
    end
  end

  context 'when an order exists' do
    before do
      order = Order.build(
        initiator_id: requestor.kyck_id,
        amount: 0,
        status: :new,
        kind: :card_request)
      OrderRepository.persist! order
    end

    it 'does not create an order' do
      expect { subject.execute({}) }.to(
        change { OrderRepository.all.count }.by(0))
    end
  end
end

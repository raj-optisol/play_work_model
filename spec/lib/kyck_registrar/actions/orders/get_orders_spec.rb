require 'spec_helper'


describe KyckRegistrar::Actions::GetOrders do

  let(:requestor) {regular_user}
  let(:uscs) {create_sanctioning_body}
  let(:club) {create_club}
  let!(:order) {create_order(requestor, club, uscs, kind: :card_request)}

  it 'should raise permission error for regular user' do
    action = KyckRegistrar::Actions::GetOrders.new requestor, club
    expect{ result = action.execute ({})}.to raise_error KyckRegistrar::PermissionsError
  end

  it 'should return 1 order for user with permission' do
    add_user_to_org(requestor, club, permission_sets:  [PermissionSet::MANAGE_MONEY])
    action = KyckRegistrar::Actions::GetOrders.new requestor, club
    result = action.execute ({})
    result.count.should == 1
  end

  it 'should return 1 order for admin user with permission' do
    auser = admin_user([PermissionSet::MANAGE_ORGANIZATION])
    action = KyckRegistrar::Actions::GetOrders.new auser, club
    result = action.execute ({})
    result.count.should == 1
  end

  context "for a sanctioning body" do
    let(:requestor) {regular_user}
    let(:uscs) {create_sanctioning_body}
    let(:club) {create_club}
    let!(:order) {create_order(requestor, club, uscs, kind: :card_request)}

    before do
      add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_REQUEST])
    end

    subject {described_class.new(requestor, uscs)}

    it "returns the orders for the sb" do
      results = subject.execute({kind: :card_request})
      results.count.should == 1
      results[0].id.should == order.id
    end
  end

  context 'with condition attributes' do
    before do
      add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_REQUEST])
    end

    subject {described_class.new(requestor, uscs)}

    it "returns an order by assigned_kyck_id" do
      results = subject.execute({ conditions: { assigned_kyck_id: requestor.kyck_id } })
      results.count.should == 1
      results[0].id.should == order.id
    end

    it "returns an order by assigned_name" do
      results = subject.execute({ conditions: { assigned_name: requestor.full_name } })
      results.count.should == 1
      results[0].id.should == order.id
    end
  end
end

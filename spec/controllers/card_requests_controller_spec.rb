require 'spec_helper'

describe CardRequestsController do
  include Devise::TestHelpers

  let!(:uscs) { create_sanctioning_body(name: 'USCS')}
  let(:club) {create_club}
  let(:requestor) {regular_user}
  let(:current_user) {regular_user}
  let(:order) {
    o = Order.build(
      initiator_id: requestor.kyck_id,
      payee_id: uscs.kyck_id,
      payee_type: 'SanctioningBody',
      payer_id: club.kyck_id,
      payer_type: 'Organization',
      kind: :card_request,
      status: :open
    )
    OrderRepository.persist(o)
  }

  before do
    sign_in_user(current_user)
    uscs.sanction(club)
    SanctioningBodyRepository.persist uscs
    OrganizationRepository.persist club
    add_user_to_org(current_user, uscs, permission_sets:[PermissionSet::MANAGE_MONEY])
  end

  describe '#new' do
    let(:order_params) {
      {
        kind: :card_request,
        payer_id:club.kyck_id,
        payer_type: 'Organization',
        payee_id: uscs.kyck_id,
        payee_type: 'SanctioningBody',
        state: nil
      }
    }
    context 'for a organization' do
      it 'calls the right action with the right args' do
        mock_execute_action(KyckRegistrar::Actions::GetOrCreateOrder,order_params, Order.new )
        get :new, organization_id: club.kyck_id
      end
    end

  end

  describe '#create' do
    let(:uscs) {create_sanctioning_body(name: 'USCS')}
    let(:card_product) { create_card_product(uscs)}
    let(:user_to_card) {regular_user}
    let(:card_request_params) {
      {
        'card_type' =>  'player',
        'user' => {
          'id' => user_to_card.kyck_id,
          'age' => user_to_card.age,
          'gender' => user_to_card.gender
        }
      }
    }

    context 'when the user is cardable' do
      before do
        @validator = Object.new
        KyckRegistrar::Validators::Cardable.stub(:new).with(any_args) {@validator}
        @validator.stub(:valid?).and_return(true)

      end
      it 'gets a card product' do
        mock_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, card_request_params, card_product )
        stub_execute_action(KyckRegistrar::Actions::AddOrderItem, nil, OrderItem.new  )
        post :create, organization_id: club.kyck_id, card_requests: [ card_request_params ], format: :json
      end

      it 'adds a new order item' do
        stub_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, card_request_params, card_product )
        action = Object.new
        action.should_receive(:execute).with({}, @validator).and_return(OrderItem.build)
        KyckRegistrar::Actions::AddOrderItem.stub(:new) {action}
        post :create, organization_id: club.kyck_id, card_requests: [card_request_params], format: :json
      end

      context 'for a team' do

        context 'that is part of a sanctioned league' do
          let(:team) {create_team_for_organization(club)}
          let(:comp) { OpenStruct.new(kyck_id: '1234', organization: {kyck_id: '4567'})}

          it 'puts the competition_id on the order_item' do
            stub_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, card_request_params, card_product )
            action = Object.new
            action.should_receive(:execute).with({competition_id: '1234'}, @validator).and_return(OrderItem.build)

            team.stub(:sanctioned_competitions) {[comp]}
            OrganizationRepository::TeamRepository.stub(:find) {team}
            KyckRegistrar::Actions::AddOrderItem.stub(:new) {action}
            post :create, team_id: team.kyck_id, card_requests: [card_request_params], format: :json
          end

          it 'uses the competition organization for the card products' do
            KyckRegistrar::Actions::GetSingleCardProduct.should_receive(:new).with(anything, anything, comp.organization, team)
            mock_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, card_request_params, card_product )
            action = Object.new
            action.should_receive(:execute).with({competition_id: '1234'}, @validator).and_return(OrderItem.build)

            team.stub(:sanctioned_competitions) {[comp]}
            OrganizationRepository::TeamRepository.stub(:find) {team}
            KyckRegistrar::Actions::AddOrderItem.stub(:new) {action}
            post :create, team_id: team.kyck_id, card_requests: [card_request_params], format: :json

          end

        end

      end
    end

    context 'when the user is not cardable' do

      it 'does not add a new order item' do
        stub_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, card_request_params, card_product )
        mock_dont_execute_action(KyckRegistrar::Actions::AddOrderItem, {} )
        post :create, organization_id: club.kyck_id, card_requests: [card_request_params], format: :json

      end

    end

  end

  describe '#destroy' do
    let(:uscs) {create_sanctioning_body(name: 'USCS')}
    let(:card_product) { create_card_product(uscs)}
    let(:user_to_card) {regular_user}
    let(:card_request_params) {
      {
        'card_type' =>  'player',
        'user' => {
          'id' => user_to_card.kyck_id,
          'age' => user_to_card.age,
          'gender' => user_to_card.gender
        }
      }
    }

    it 'removes a card', broken: true do
      stub_execute_action(KyckRegistrar::Actions::GetSingleCardProduct, [ card_request_params ], card_product )
      mock_execute_action(KyckRegistrar::Actions::RemoveOrderItem, {id: '1234'}, card_product )
      delete :destroy, organization_id: club.kyck_id, id: '1234', format: :json
    end
  end

  describe '#index' do
    context 'for a sanctioning body' do

      it "calls the right action" do
        mock_execute_action(
          KyckRegistrar::Actions::GetOrders,
          { order: "updated_at desc", limit: 25, offset: 0,
            conditions: { "status_dne" => :new, "kind" => :card_request }
          }, [order]
        )
        get :index, sanctioning_body_id: uscs.kyck_id, format: :json
        json.count.should == 1
        json[0]['id'].should == order.id
      end

      context 'when filtered by organization' do

        it "calls the right action" do
          mock_execute_action(
            KyckRegistrar::Actions::GetOrders,
            { order: "updated_at desc", limit: 25, offset: 0, conditions:
              { "kind" => :card_request, "payer_id" => club.kyck_id }
            }, [order]
          )
          get :index, sanctioning_body_id: uscs.kyck_id, filter: {"organization_id" =>  club.kyck_id} ,  format: :json
          json.count.should == 1
          json[0]['id'].should == order.id
        end


      end

    end
  end
  describe '#show' do
    let(:card_product) { create_card_product(uscs)}
    let(:order_params) {
      {
        id: 'current'
      }
    }

    before do
      mock_execute_action(KyckRegistrar::Actions::GetOrCreateOrder, order_params, order )
    end


    subject {get :show, organization_id: club.kyck_id, id: 'current'}

    context 'for the current request' do
      it 'gets the card request' do
        subject
      end

      context 'when the order is authorized' do
        before do
          order.payment_status = :authorized
        end

        context 'and not in progress' do
          before do
            order.status = :submitted
            order._data.save!
          end

          it 'can be voided' do
            subject
            assigns['can_void'].should be_true
          end
        end

        context 'and in progress' do
          before do
            order.status = :in_progress
            order._data.save!
          end

          it 'cannot be voided' do
            subject
            assigns['can_refund'].should be_false
            assigns['can_void'].should be_false
          end
        end
      end

      context 'when the order is settled' do
        before do
          order.payment_status = :settled
        end

        context 'and not in progress' do
          before do
            order.status = :submitted
            order._data.save!
          end
          it 'can be refunded' do
            subject
            assigns['can_refund'].should be_true
          end

          it 'cannot be voided' do
            subject
            assigns['can_void'].should be_false
          end
        end
      end
    end
  end
end

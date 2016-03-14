require 'spec_helper'

describe SanctioningRequestsController, type: :controller do

  let(:club) {create_club}
  let(:requestor) {regular_user}
  let!(:sanctioning_body) {create_sanctioning_body}

  def sign_in_user_with_manage_request
    club.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_REQUEST]})
    UserRepository.persist(requestor)
    sign_in_user(requestor)
  end

  describe '#new' do

    before(:each) do
      sign_in_user_with_manage_request
      sanctioning_body
    end

    it 'populates org' do
      get :new, organization_id: club.kyck_id
      assigns[:org].kyck_id.should == club.kyck_id
    end

    it 'populates sanctioning request' do
      get :new, organization_id: club.kyck_id
      assigns[:sanctioning_request].should_not be_nil
    end

    it 'lets sanctioning request serializable' do
      get :new, organization_id: club.kyck_id
      assigns[:sanctioning_request]
    end

    context 'when there is a pending or recently denied request' do
      let(:sanctioning_request) {create_sanctioning_request(sanctioning_body, club, requestor)}

      it 'redirects to show page for the request' do
        controller.stub(:pending_or_denied_recently?).and_return(sanctioning_request)
        get :new, organization_id: club.kyck_id.to_s
        response.should redirect_to organization_sanctioning_request_path(club, sanctioning_request)
      end
    end

    context 'when the club is already sanctioned' do
      before(:each) do
        sanctioning_body.sanction club
        SanctioningBodyRepository.persist sanctioning_body
      end

      it 'redirects to organization', broken: true do
        get :new, organization_id: club.kyck_id
        response.should redirect_to organization_path(club)
      end

    end
  end

  describe '#show' do
    before(:each) do
      sign_in_user_with_manage_request
      stub_execute_action(KyckRegistrar::Actions::GetOrders, nil, [ Order.build ])
    end

    let(:sanctioning_request) {
      r = SanctioningRequest.build(issuer: requestor._data, target: sanctioning_body._data, on_behalf_of: club._data)
      SanctioningRequestRepository.persist! r
      r
    }

    it 'calls the action' do
      mock_execute_action(KyckRegistrar::Actions::GetSanctioningRequests, nil, [ sanctioning_request ])
      get :show, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id

    end

    it 'assigns the sanctioning request' do
      stub_execute_action(KyckRegistrar::Actions::GetSanctioningRequests, nil, [ sanctioning_request ])
      get :show, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
      assigns(:sanctioning_request).should_not be_nil
    end

    it 'assigns obj property' do
      stub_execute_action(KyckRegistrar::Actions::GetSanctioningRequests, nil, [ sanctioning_request ])
      get :show, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
      assigns(:obj).kyck_id.should == sanctioning_body.kyck_id
    end

    context 'for an organization' do

      it 'calls the action' do
        mock_execute_action(KyckRegistrar::Actions::GetSanctioningRequests, nil, [ sanctioning_request ])
        get :show, organization_id: club.kyck_id, id: sanctioning_request.kyck_id
      end

      it 'assigns obj property' do
        stub_execute_action(KyckRegistrar::Actions::GetSanctioningRequests, nil, [ sanctioning_request ])
        get :show, organization_id: club.kyck_id, id: sanctioning_request.kyck_id
        assigns(:obj).id.should == club.id
      end

    end
  end

  describe '#index' do
    let(:org_requests) { [create_sanctioning_request(sanctioning_body, club, requestor)] }
    before(:each) do
      mock_execute_action(KyckRegistrar::Actions::GetSanctioningRequests,
                          { limit: 25, offset: 0, conditions: {} },
                          org_requests)

      sign_in_user(admin_user)
      Oriented.graph.commit
    end

    it 'should return json' do
      get :index, organization_id: club.kyck_id.to_s,  format: :json
      json[0]['on_behalf_of']['name'].should == club.name
    end

    it 'should return the user' do
      get :index, organization_id: club.kyck_id.to_s,  format: :json
      json[0]['issuer']['id'].should == requestor.kyck_id.to_s
    end

  end

  describe '#create' do

    context 'when a user has the right permission' do
      let(:sanctioning_params) {
        {
          'doc' => {'user_id' => requestor.kyck_id},
          'president' => {'user_id' => requestor.kyck_id},
          'payload'=> {'number_of_players_male_U11'=> '30', 'number_of_players_female_U11'=> '20'},
          'kind' => 'club'
        }
      }

      before(:each) do
        club.add_staff(requestor, {title: 'Admin', permission_sets:[PermissionSet::MANAGE_REQUEST]})
        UserRepository.persist requestor
        sign_in_user(requestor)
      end

      context 'when no sanctioning_request product' do

        let(:sanctioning_request){
          SanctioningRequestRepository.persist SanctioningRequest.build
        }

        it 'should call the action' do
          a = mock_execute_action(KyckRegistrar::Actions::RequestSanction, sanctioning_params, sanctioning_request)

          a.stub(:subscribe)
          a.stub(:on).and_yield(sanctioning_request, nil, nil)

          post :create, organization_id: club.kyck_id, sanctioning_request: sanctioning_params
        end

        it 'redirects to the org sanctioning request page' do
          a = stub_execute_action(KyckRegistrar::Actions::RequestSanction, sanctioning_params, sanctioning_request)

          a.stub(:subscribe)
          a.stub(:on).and_yield(sanctioning_request, nil, nil)

          post :create, organization_id: club.kyck_id.to_s, sanctioning_request: sanctioning_params
          response.should redirect_to organization_sanctioning_request_path(club, sanctioning_request)
        end
      end

      context 'when sanctioning request product exist' do
        let(:order){ order = OrderRepository.persist(Order.build({initiator_id: requestor.kyck_id, payer_id: club.kyck_id, payer_type: club.class.to_s, payee_id: sanctioning_body.kyck_id, payee_type: sanctioning_body.class.to_s, kind: 'invoice'})) }
        let(:sanctioning_request){
          SanctioningRequestRepository.persist ( SanctioningRequest.build(status: 'pending_payment', order_id: order.id) )
        }

        it 'redirects to the order page' do
          #Arrange
          a = stub_execute_action(KyckRegistrar::Actions::RequestSanction, sanctioning_params, sanctioning_request)
          req = create_sanctioning_request(sanctioning_body, club, requestor, { status: :pending_payment, kind: :club })
          req.order_id = order.id
          SanctioningRequestRepository.persist req

          a.stub(:subscribe)
          a.stub(:on).and_yield(req, nil, nil)

          #Act
          post :create, organization_id: club.kyck_id, sanctioning_request: sanctioning_params

          #Assert
          response.should redirect_to new_order_payments_path(order.id)
        end
      end

    end
  end

  describe '#approve' do
    context 'when a user has the right permission' do
      let(:sanctioning_request) {
        create_sanctioning_request(sanctioning_body, club, requestor)
      }

      let(:input) { {kyck_id: sanctioning_request.kyck_id} }

      before(:each) do
        sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets:[PermissionSet::MANAGE_REQUEST]})
        UserRepository.persist requestor
        sign_in_user(requestor)
      end

      it 'should call the right action' do
        mock_execute_action(KyckRegistrar::Actions::ApproveSanction, input, sanctioning_request)
        post :approve, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
      end

      it 'redirects to the club sanctioning request page' do
        stub_execute_action(KyckRegistrar::Actions::ApproveSanction, input, sanctioning_request)
        post :approve, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
        response.should redirect_to sanctioning_body_sanctioning_request_path(sanctioning_body, sanctioning_request)
      end
    end
  end

  describe '#reject' do
    context 'when a user has the right permission' do
      let(:sanctioning_request) {
        create_sanctioning_request(sanctioning_body, club, requestor)
      }
      let(:order){ order = OrderRepository.persist(Order.build({initiator_id: requestor.kyck_id, payer_id: club.kyck_id, payer_type: club.class.to_s, payee_id: sanctioning_body.kyck_id, payee_type: sanctioning_body.class.to_s, kind: 'invoice'})) }

      let(:input) { {kyck_id: sanctioning_request.kyck_id} }

      before(:each) do
        sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets:[PermissionSet::MANAGE_REQUEST]})
        UserRepository.persist requestor
        sign_in_user(requestor)
      end

      it 'should call the right action' do
        input = {kyck_id: sanctioning_request.kyck_id}
        mock_execute_action(KyckRegistrar::Actions::RejectSanction, input, sanctioning_request)
        post :reject, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
      end

      it 'redirects to the org sanctioning request page' do
        stub_execute_action(KyckRegistrar::Actions::RejectSanction, input, sanctioning_request)
        post :reject, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id
        response.should redirect_to sanctioning_body_sanctioning_request_path(sanctioning_body, sanctioning_request)
      end

      it 'refunds the order' do
        mock_execute_action(KyckRegistrar::Actions::RefundOrder)
        sanctioning_request.status = :denied
        sanctioning_request.order_id = order.id
        a = stub_execute_action(KyckRegistrar::Actions::RejectSanction, input, sanctioning_request)

        a.stub(:subscribe)
        a.stub(:on).and_yield(sanctioning_request)

        post :reject, sanctioning_body_id: sanctioning_body.kyck_id, id: sanctioning_request.kyck_id, refund:true
        response.should redirect_to sanctioning_body_sanctioning_request_path(sanctioning_body, sanctioning_request)
      end
    end
  end

  def org_requests
    @user = regular_user
    @sb = create_sanctioning_body
    @org = create_club

    o1 = SanctioningRequest.build(status: :pending, issuer: @user._data, on_behalf_of: @org._data, target: @sb._data,  payload: {}.to_json)
    SanctioningBodyRepository.persist o1
    [o1]
  end
end

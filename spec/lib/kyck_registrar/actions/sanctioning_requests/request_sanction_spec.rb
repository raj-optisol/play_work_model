require 'spec_helper'


describe KyckRegistrar::Actions::RequestSanction do

  let(:club) {
    create_club
  }
  let(:requestor) {regular_user({first_name: 'Billy', last_name: 'Bob', email: 'nouser@kyck.com'})}
  let(:sanctioning_body) { create_sanctioning_body }

  let(:sr_params) {
    {
      payload: {
        number_of_players_male_U11: 20,
        number_of_players_male_U12: 20,
        number_of_players_male_adult: 20,
        number_of_players_female_U11: 20,
        number_of_players_female_U12: 20,
        number_of_players_female_adult: 20
      }
    }
  }

  before(:each) do
    add_user_to_org(requestor, club, {title: "registrar", permission_sets: [PermissionSet::MANAGE_STAFF]}, UserRepository)
    @product = SanctioningRequestProduct.build({:kind => 'club', :amount=>1000.0, :sanctioning_body_id => sanctioning_body.kyck_id})
    SanctioningRequestProductRepository.persist @product
  end

  it 'creates a sanctioning request with status pending' do
    academy = create_academy()
    action = KyckRegistrar::Actions::RequestSanction.new requestor, academy, sanctioning_body
    result = action.execute(sr_params)

    orgreq = SanctioningRequestRepository.find(result.id)
    orgreq.issuer.id.should_not be_nil
    orgreq.status.should == :pending
  end

  it "defaults to club" do
    action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
    result = action.execute sr_params
    result.kind.should == :club
  end

  it "captures the payload" do
    action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
    result = action.execute sr_params
    json = JSON.parse(result.payload)
    json["number_of_players_male_U11"].should == 20
  end

  context 'when the payload is empty' do
    it 'handles it' do
      action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      result = action.execute
      json = JSON.parse(result.payload)
      assert_equal JSON.parse("{}"), json
    end
  end

  it "publishes a request created event" do
    academy = create_academy()
    action = KyckRegistrar::Actions::RequestSanction.new requestor, academy, sanctioning_body
    listener = double('listener')
    listener.should_receive(:sanctioning_request_created).with(instance_of(SanctioningRequest), instance_of(Organization), instance_of(SanctioningBody))
    action.subscribe(listener)
    action.execute(sr_params)

  end

  it "sets the org to on_behalf_of" do
    action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
    result = action.execute sr_params
    result.on_behalf_of.kyck_id.should == club.kyck_id
  end

  context "when contacts to existing users are provided" do
    let(:doc) {regular_user}
    let(:input) {
      sr_params[:doc] = {title: 'doc', user_id: doc.kyck_id }
      sr_params
    }

    it "calls add staff" do
      mock_execute_action(KyckRegistrar::Actions::AddStaff, {"user_id"=> doc.kyck_id, "title"=> 'doc'})

      action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      action.execute(input)
    end

    context "when the provided attributes are invalid" do
      let(:input) {
        sr_params[:doc] = {title: 'doc', user_id: "" }
        sr_params[:president] = {title: 'president', user_id: "" }
        sr_params
      }
      it "does not" do
        should_not_execute_action(KyckRegistrar::Actions::AddStaff, {"user_id"=> "", "title"=> 'doc'})

        action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
        action.execute(input)

      end
    end

  end

  context "when contacts to new users are provided" do
    let(:input) {
      sr_params[:doc] = {"title"=> 'doc', "first_name"=> 'Barney', "last_name"=> 'Rubble', "email"=>'barney@rubble.com', "phone_number"=> '777-777-8888' }
      sr_params[:president] = {"title"=> 'president', "first_name"=> 'Billy', "last_name"=> 'Bob', "email"=>'billy@bob.com', "phone_number"=> '777-777-9999' }
      sr_params
    }

    it "calls add staff" do
      # mock_execute_action(KyckRegistrar::Actions::AddStaff, input[:doc])
      orgid = requestor.staff_for[0].id
      action = KyckRegistrar::Actions::RequestSanction.new requestor, club, sanctioning_body
      sr = action.execute(input)
      o = OrganizationRepository.find(orgid)
      o.staff.count.should == 3

    end
  end

  context "when a sanctioning request already exists" do

    let!(:sanctioning_request) { create_sanctioning_request(sanctioning_body, club, requestor)}
    subject{described_class.new(requestor, club, sanctioning_body)}

    it "returns that request" do
      request = subject.execute({players: {u12: {boys: 20, girls: 20}}})
      request.id.should == sanctioning_request.id
    end
  end

end

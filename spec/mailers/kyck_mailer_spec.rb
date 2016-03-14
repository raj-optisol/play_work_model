# encoding: UTF-8
require 'spec_helper'

describe KyckMailer do
  describe 'staff_added!' do
    let(:to) { { email: 'fred@bedrockisp.com', name: 'Fred Flintstone' } }
    let(:from) { { email: 'barney@bedrockisp.com', name: 'Barney' } }

    let(:org_name) { 'Betty Pounders' }

    let(:mail) { KyckMailer.staff_added!(org_name, to, from) }

    it 'sets the template name' do
      expect(mail.template_id).to eq("staff-member-added")
    end

    it "sets the correct to address" do
      expect(mail.email).to eq(to[:email])
    end

    context 'when the requestor has  a fake email' do
      let(:to) { { email: 'fred@kyckfake.com', name: 'Fred Flintstone' } }

      it 'does not send it' do
        mail.should be_a ActionMailer::Base::NullMail
      end
    end
  end

  describe 'cards_declined!' do
    let(:uscs) { create_sanctioning_body }
    let(:club) { create_club }
    let(:requestor) { regular_user }
    let(:order) { create_order(requestor, club, uscs) }
    let(:player) { regular_user }
    let(:cards) { [create_card(player, club, uscs)] }

    let(:mail) do
      KyckMailer.cards_declined!(order, cards, requestor, 'Missing Waivers')
    end

    it 'has a subject' do
      expect(mail.template_id).to eq("card-request-declined")
    end

    context 'when the requestor has  a fake email' do
      let(:requestor) { regular_user(email: 'fake@kyckfake.com') }

      it 'does not send it' do
        mail.should be_a ActionMailer::Base::NullMail
      end
    end
  end

  describe 'staff_card_created!' do
    let(:to) { { email: 'fred@bedrockisp.com', name: 'Fred Flintstone' } }
    let(:from) { { email: 'barney@bedrockisp.com', name: 'Barney' } }

    let(:org_name) { 'Betty Pounders' }

    let(:mail) { KyckMailer.staff_card_created!(org_name, to, from) }

    it "has the correct template name" do
      expect(mail.template_id).to eq("staff-card-requested")
    end

    it 'send the to name' do
      expect(mail.name).to eq(to[:name])
    end
    context 'when the requestor has  a fake email' do
      let(:to) { { email: 'fred@kyckfake.com', name: 'Fred Flintstone' } }

      it 'does not send it' do
        mail.should be_a ActionMailer::Base::NullMail
      end

    end
  end
  
  describe "organization name changed" do
    let(:values) { { id: 1, state: "NC", old_name: "Old Name", new_name: "New Name" } }

    let(:mail) { KyckMailer.organization_name_changed!(values) }
    
    it "has the correct template name" do
      expect(mail.template_id).to eq("organization-name-changed")
    end

    it "sets the name" do
      expect(mail.name).to eq("US Club Soccer")
    end

    it "sets the 'email' to admin@usclubsoccer.org" do
      expect(mail.email).to eq("admin@usclubsoccer.org")
    end
  end

  describe "organization help request" do

    let(:values) { { org_id: 1, org_name: "A Name", email: "email@orgname.com", role: "Admin", state: "NC" } }
    let(:user) { regular_user }
    let(:mail) { KyckMailer.organization_help_request!(user, values) } 

    it "sets the template id" do
      expect(mail.template_id).to eq("organization-help-request")
    end

    it "sets the email to value[:org_name]" do
      expect(mail.name).to eq(values[:org_name])
    end
  end

  describe "notification settings changed" do

    let(:user) { regular_user }
    let(:mail) { KyckMailer.notification_settings_changed!(user) }

    it "sets the template id" do
      expect(mail.template_id).to eq("account-information-updated")
    end

    it "sets the name to user.full_name" do
      expect(mail.name).to eq(user.full_name)
    end
  end

  describe "purchase_completed" do
    let(:payer) { create_sanctioning_body }
    let(:payee) { create_club }
    let(:order) { create_order(regular_user, payer, payee, status: :submitted) }
    let(:payment_account) { PaymentAccount.build(obj_type: payer.class.to_s, obj_id: payer.kyck_id, balance: 10000) }
    let(:transaction) { create_payment_transaction(payment_account.id, order.id) }
    let(:purchaser) { regular_user }
    let(:mail) { KyckMailer.purchase_completed!(purchaser, transaction, nil) }

    it "sets the template id" do
      expect(mail.template_id).to eq("payment-receipt")
    end
    
    it "sets the name to purchaser.full_name" do
      expect(mail.name).to eq(purchaser.full_name)
    end
                      
  end

  describe "card request approved" do
    let(:users) { ["Test User", "Jane Doe"] }
    let(:requester) { ["test@testsite.com", "Test User"] }
    let(:mail) { KyckMailer.card_request_approved!(requester, nil, users) }

    it "sets the template id" do
      expect(mail.template_id).to eq("card-request-approved")
    end

    it "sets the name to the second element in requester" do
      expect(mail.name).to eq(requester[1])
    end

  end

  describe 'sanctioning request approved' do
    let(:uscs) { create_sanctioning_body }
    let(:requestor) { regular_user }
    let(:org) { create_club }
    let(:sr) { create_sanctioning_request(uscs, org, requestor) }
    let(:opts) { { admin: regular_user, rep: regular_user } }
    let(:mail) { KyckMailer.sanctioning_request_approved!(sr, opts) }

    before do
      create_location_for_locatable(org)
    end

    it "sets the template id" do
      expect(mail.template_id).to eq("sanctioning-request-approved")
    end

    it "sets the email to the requestor's email" do
      expect(mail.email).to eq(requestor.email)
    end
  end

  describe "sanctioning request declined" do
    let(:uscs) { create_sanctioning_body }
    let(:requestor) { regular_user }
    let(:mail) { KyckMailer.sanctioning_request_declined!(requestor, nil, regular_user) }

    it "sets the template id" do
      expect(mail.template_id).to eq("sanctioning-request-declined")
    end

    it "sets the name of the requestor to name" do
      expect(mail.name).to eq(requestor.full_name)
    end
  end

  describe "transaction-survey" do
    let(:purchaser) { regular_user }
    let(:mail) { KyckMailer.transaction_survey!(purchaser) }

    it "sets the template id" do
      expect(mail.template_id).to eq("transaction-survey")
    end
    
    it "sets the email to purchaser.email" do
      expect(mail.email).to eq(purchaser.email)
    end
                      
  end
end

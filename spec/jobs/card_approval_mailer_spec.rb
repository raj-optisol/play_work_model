# encoding: UTF-8
require 'spec_helper'
# Specs for CardApprovalMailer
module Jobs
  describe CardApprovalMailer do
    subject { described_class.new }

    describe '#run' do

      let!(:org) do
        create_club
      end

      let!(:staff) do
        org.add_staff(regular_user, title: 'Registrar')
      end

      let!(:sb) do
        create_sanctioning_body
      end

      let!(:approved_card) do
        create_card(
          regular_user,
          org,
          sb,
          status: :approved,
          approval_email_sent: false,
          order_id: card_order.id
        )
      end

      let!(:unapproved_card) do
        create_card(
          regular_user,
          org,
          sb,
          status: :submitted,
          approval_email_sent: false,
          order_id: card_order.id
        )
      end

      let!(:card_order) do
        create_order(regular_user, org, sb)
      end

      let(:approval_handler) do
        ::CardApprovalEmailHandler.new
      end

      before :each do
        approval_handler.add_to_queue(
          [
            {full_name: approved_card.full_name,
             order_id: card_order.id,
             status: :approved,
             order_item_id: '1234'}
          ])
      end

      it 'should destroy any CardEmail records' do
        expect(::CardMail.count).to be > 0
        subject.run
        expect(::CardMail.count).to be_zero
      end

      it 'sends an email listing all newly approved cards for each order' do
        KyckRegistrar.notifier.should_receive(:card_request_approved)
        subject.run
      end

      it 'does not send an email if not running' do
        count_before = ::CardMail.count
        expect(count_before).to be > 0
        subject.instance_variable_set :@running, false
        expect(::CardMail.count).to eq count_before
      end

      it 'should be running' do
        expect(subject.running?).to be false
        subject.run
        expect(subject.running?).to be true
      end

      it 'should not be running after #stop_processing' do
        subject.run
        subject.stop_processing
        expect(subject.running?).to be false
      end
    end
  end
end

# encoding: UTF-8
# Tests for the CardHandler helper.
require 'spec_helper'

describe CardHandler do
  describe 'when card gets approved' do
    subject { CardApprovalEmailHandler.new }

    let!(:cards) do
      [
        FactoryGirl.create(
          :card,
          expires_on: 1.year.from_now,
          first_name: 'John',
          last_name: 'Doe',
          status: :approved,
          order_id: 1
        ),
        FactoryGirl.create(
          :card,
          expires_on: 1.year.from_now,
          first_name: 'Catie',
          last_name: 'Duran',
          status: :approved,
          order_id: 1
        ),
        FactoryGirl.create(
          :card,
          expires_on: 1.year.from_now,
          first_name: 'Jane',
          last_name: 'Doe',
          status: :new,
          order_id: 1
        ),
        FactoryGirl.create(
          :card,
          expires_on: 1.year.from_now,
          first_name: 'Jack',
          last_name: 'Ripper',
          status: :approved,
          order_id: 2
        )
      ]
    end

    let!(:org) do
      create_club
    end

    let!(:staff) do
      org.add_staff(regular_user, title: 'Registrar')
    end

    let!(:sb) do
      create_sanctioning_body
    end

    let!(:card_order1) do
      create_order(regular_user, org, sb, id: 1)
    end

    let!(:card_order2) do
      create_order(regular_user, org, sb, id: 2)
    end

    it 'adds a new record per order to the card_mails table' do
      # subject.add_to_queue(cards)
      # mails = CardMail.where(order_id: cards.first.order_id)
      # mails.count.should == 1
      pending
    end

    it 'inserts all the approved users into a single record' do
      # subject.add_to_queue(cards)
      # mails = CardMail.where(order_id: cards.first.order_id).first
      # users = mails.users.split(',')
      # users.count.should == 3 # Add one to include the empty string at end
      pending
    end

    it 'escapes cards with a different status than approved' do
      # subject.add_to_queue(cards)
      # mails = CardMail.where(order_id: cards.first.order_id).first
      # users = mails.users.split(',')
      # users.should_not include('Jane Doe')
      pending
    end
  end
end

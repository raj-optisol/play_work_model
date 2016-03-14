# encoding: UTF-8
require 'spec_helper'

describe Card do
  let(:user) { regular_user }
  let(:club) { create_club }
  let(:uscs) { create_sanctioning_body }

  describe '#renew' do
    context 'when card is for a player' do
      subject(:card) do
        create_card(user, club, uscs,
                    status: :new, message_status: :requestor_response_required)
      end

      it { expect { card.renew }.to change(card, :status).to(:approved) }
      it { expect { card.renew }.to change(card, :is_renewal).to(true) }
      it { expect { card.renew }.to change(card, :message_status).to(:read) }
    end

    context 'when card is for a staff' do
      subject(:card) do
        create_card(user, club, uscs, kind: :staff, status: :new)
      end

      it 'should set the card status to new' do
        card.renew
        expect(card.status).to eq(:new)
      end
    end
  end

  describe '#reset' do
    subject(:card) { create_card(user, club, uscs, inactive_on: Time.now) }

    it { expect { card.reset }.to change(card, :status).to(:new) }
    it { expect { card.reset }.to change(card, :approved_on).to(nil) }
    it { expect { card.reset }.to change(card, :inactive_on).to(nil) }
    it { expect { card.reset }.to change(card, :expires_on) }
  end

  describe '#reset_expiration' do
    context 'when it is a player card' do
      subject(:card) { create_card(user, club, uscs) }
      it 'should set the expiration date to current or next season' do
        now = Date.today
        year = now.year + (~~now.month / 7)
        card.send(:reset_expiration)
        expect(card.expires_on).to eq(Time.new(year, 8, 1).to_i)
      end
    end

    context 'when it is a staff card' do
      subject(:card) { create_card(user, club, uscs, kind: :staff) }
      it 'should set the expiration date to next season or one season after' do
        now = Date.today
        year = now.year + (~~now.month / 7) + 1
        card.send(:reset_expiration)
        expect(card.expires_on).to eq(Time.new(year, 8, 1).to_i)
      end
    end
  end

  describe 'documents' do
    describe '#add_document' do
      let!(:doc) { create_document_for_user(user) }

      it 'adds a document to the card' do
        expect do
          d = subject.add_document(doc)
          DocumentRepository.persist(d)
        end.to change { subject.documents.count }.by(1)
      end
    end
  end
end

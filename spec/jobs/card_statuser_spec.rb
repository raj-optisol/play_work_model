require 'spec_helper'

module Jobs
  describe CardStatuser do

    let(:expired_card) {FactoryGirl.create(:card, :expires_on => 1.year.ago, :first_name => 'John', :last_name => 'Doe')}
    let(:unexpired_card) {FactoryGirl.create(:card, :expires_on => 1.year.from_now, :first_name => 'John', :last_name => 'Doe')}

    subject { described_class.new }

    describe "#run" do
      context "for expired cards" do
        it "updates the card's status as expired" do
          expect(expired_card.status).not_to eq :expired
          subject.run
          c = CardRepository.find_by_attrs(:conditions => {:kyck_id => expired_card.kyck_id}).first
          expect(c.status).to eq :expired
        end
      end

      context "for unexpired cards" do
        it "leaves the card status as it was" do
          expect(unexpired_card.status).not_to eq :expired
          subject.run
          c = CardRepository.find_by_attrs(:conditions => {:kyck_id => unexpired_card.kyck_id}).first
          expect(c.status).not_to eq :expired
        end

        it "leaves the card's duplicate_lookup_hash as it was" do
          unexpired_card.set_duplicate_lookup_hash
          unexpired_card.save!
          expect(unexpired_card.duplicate_lookup_hash).not_to be_nil
          subject.run
          c = CardRepository.find_by_attrs(:conditions => {:kyck_id => unexpired_card.kyck_id}).first
          expect(c.duplicate_lookup_hash).not_to be_nil
        end
      end
    end
  end
end

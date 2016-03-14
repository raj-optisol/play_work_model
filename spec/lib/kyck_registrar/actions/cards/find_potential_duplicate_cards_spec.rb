require 'spec_helper'

module KyckRegistrar
  module Actions
    describe FindPotentialDuplicateCards do

      let(:uscs) { create_sanctioning_body }
      let(:org)  { create_club }
      let(:comp) { create_competition(name: 'Great Cup', start_date: 1.day.from_now, end_date: 6.months.from_now) }
      let(:requestor) { regular_user }
      let(:carded_user) { regular_user(birthdate: 8.years.ago) }
      let!(:card) { create_card(carded_user, uscs, uscs, { status: :new, duplicate_lookup_hash: 'imadup' }) }


      describe "#execute" do
        context "for sanctioning bodies" do
          subject{described_class.new(requestor, card, nil, uscs)}

          context "when the user has permission to search cards for the sanctioning body" do
            before do
              add_user_to_org(requestor, uscs, permission_sets: [PermissionSet::MANAGE_CARD])
            end

            context "when duplicate cards exists based on the duplicate lookup hash" do
              let(:other_user) { regular_user(first_name: carded_user.first_name, last_name: carded_user.last_name, birthdate: carded_user.birthdate) }
              let!(:dup_card)  { create_card(other_user, uscs, uscs, status: :approved, duplicate_lookup_hash: card.duplicate_lookup_hash)}

              it "returns an array with all the duplicates" do
                cards = subject.execute(duplicate_lookup_hash: card.duplicate_lookup_hash)
                cards.map(&:kyck_id).should include(dup_card.kyck_id)
              end

              it "doesn't return the passed in card" do
                cards = subject.execute(duplicate_lookup_hash: card.duplicate_lookup_hash)
                cards.map(&:kyck_id).should_not include(card.kyck_id)
              end
            end

            context "when no duplicate cards are found based on the duplicate lookup hash" do
              it "returns an empty array" do
                cards = subject.execute(duplicate_lookup_hash: card.duplicate_lookup_hash)
                cards.count.should == 0
              end
            end
          end

          context "when the user does NOT have permission to search cards for the sb" do
             it "raises a permissions error" do
                expect {subject.execute}.to raise_error
             end
          end
        end


        context "for competitions" do
          subject{described_class.new(requestor, card, comp)}


          context "when the user has permission to search cards for the competition" do
            before do
              add_user_to_org(requestor, comp, permission_sets: [PermissionSet::MANAGE_CARD])
            end

            context "when duplicate cards exists based on the duplicate lookup hash" do
              let(:other_user) { regular_user(first_name: carded_user.first_name, last_name: carded_user.last_name, birthdate: carded_user.birthdate) }
              let!(:dup_card)  { create_card(other_user, org, uscs, { status: :approved, duplicate_lookup_hash: card.duplicate_lookup_hash })}


              it "returns an array with all the duplicates" do
                cards = subject.execute({ duplicate_lookup_hash: card.duplicate_lookup_hash })
                cards.map(&:kyck_id).should include(dup_card.kyck_id)
              end

              it "doesn't return the passed in card" do
                cards = subject.execute({ duplicate_lookup_hash: card.duplicate_lookup_hash })
                cards.map(&:kyck_id).should_not include(card.kyck_id)
              end
            end

            context "when no duplicate cards are found based on the duplicate lookup hash" do
              it "returns an empty array" do
                cards = subject.execute({ duplicate_lookup_hash: card.duplicate_lookup_hash })
                cards.count.should == 0
              end
            end
          end

          context "when the user does NOT have permission to search cards for the competition" do
             it "raises a permissions error" do
                expect {subject.execute}.to raise_error
             end
          end
        end
      end
    end
  end
end

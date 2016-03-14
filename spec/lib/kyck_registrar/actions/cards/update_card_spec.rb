require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateCard do

      describe "#execute" do

        let(:requestor) {regular_user}
        let(:uscs) {create_sanctioning_body}
        let(:club) {create_club}
        let(:user) {regular_user}
        let(:card) {
          create_card(user, club, uscs,
          {
            status: 'approved',
            first_name: 'Name',
            middle_name: 'Name',
            last_name: 'Name',
            birthdate: 9.years.ago
          })
        }


        subject { described_class.new(requestor, card)}

        before  do
          requestor.stub(:can_manage?) { true}
          CardRepository.stub(:persist) { card}
        end

        it "updates the card" do
          c = subject.execute(status: :inactive)
          c.status.should == :inactive
        end

        context "user attributes" do

          let(:card_params) {
            {
              first_name: 'NewCard',
              middle_name: 'Middle',
              last_name: 'Jones',
              birthdate: 8.years.ago
            }.with_indifferent_access
          }

          let(:updated_card) {subject.execute(card_params)}

          it "updates the name attributes" do
            %w(first_name middle_name last_name).each do |attr|
              updated_card.send(attr).should == card_params[attr]
            end
          end

          it "changes the birthdate" do
            updated_card.birthdate.should == card_params[:birthdate ].to_date
          end

          it "generates the card duplicate lookup hash" do
            lookup = [updated_card.first_name.downcase, updated_card.last_name.downcase, updated_card.birthdate]
            updated_card.duplicate_lookup_hash.should == Digest::MD5.hexdigest(lookup.join)
          end

          context "when the birthdate is a string" do

            let(:card_params) {
              {
                first_name: 'NewCard',
                middle_name: 'Middle',
                last_name: 'Jones',
                birthdate: "06/09/2000"
              }.with_indifferent_access
            }

            it "changes the birthdate" do
              updated_card.birthdate.should == Date.strptime("06/09/2000", '%m/%d/%Y')
            end

          end

          context "when the card is being processed" do
            let(:card_params) {
              {
                first_name: 'NewCard',
                middle_name: 'Middle',
                last_name: 'Jones',
                birthdate: "06/09/2004",
                status: :processed
              }.with_indifferent_access
            }

            before do
              card.status = :new
              card._data.save
            end

            it "sets the processed date" do
              updated_card.processed_on.should_not be_nil
            end


          end
        end

        context "when the card is being inactivated" do
          it "sets the inactive date" do
            c = subject.execute(status: :inactive)
            c.status.should == :inactive
            c.inactive_on.should_not be_nil
          end
        end

        context "when the card is inactive" do

          before do
            card.status = :inactive
            card.inactive_on = Time.now.to_i
            card._data.save
          end
          context "and it's being approved again" do
            it "clears the inactive date" do
              c = subject.execute(status: :approved)
              c.status.should == :approved
              c.inactive_on.should be_nil
            end
          end
        end

        context "for a competition" do
          let(:comp) {create_competition}
          let(:league_admin) {regular_user}

          subject { described_class.new(league_admin, card)}
          before do
            card.stub(:processor)  { comp }
            league_admin.stub(:can_manage?).and_return(false, true)
          end

          it "updates the card" do
            c = subject.execute(status: :inactive)
            c.status.should == :inactive
          end
        end
      end
    end
  end
end

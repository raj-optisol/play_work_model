require 'spec_helper'

module KyckRegistrar
  module Import
    describe ImportCSV do
      let(:requestor) {regular_user} 
      let(:club) {create_club} 
      let(:csv) { CSV.open("#{Rails.root}/spec/support/import_players.csv")}

      describe "#initialize" do
        it "takes a club, csv source, and an initiator" do
          expect {described_class.new(club, requestor, csv)}.to_not raise_error
        end
      end
    end
  end
end

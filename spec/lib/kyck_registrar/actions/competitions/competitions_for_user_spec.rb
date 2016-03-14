# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CompetitionsForUser do

      subject { KyckRegistrar::Actions::CompetitionsForUser }

      it "requires a requestor" do
        expect { subject.new }.to raise_error ArgumentError
      end

      describe "#execute" do
        let(:comp) { create_competition(name: "The Comp 1", start_date:DateTime.now, end_date:(DateTime.now+6.months)) }

        context "for a user" do
          let(:requestor) { regular_user }

          before(:each) do
            comp.add_staff(requestor, title:"Coach", permission_sets: [PermissionSet::MANAGE_COMPETITION])
            CompetitionRepository.persist! comp
          end

          it "returns the competitions for the requestor" do
            action = subject.new(requestor)
            comps = action.execute
            comps.count.should == 1
          end
        end
      end
    end
  end
end

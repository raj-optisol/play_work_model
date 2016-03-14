require 'spec_helper'
require_relative '../../../../lib/kyck_registrar/actions/create_division'


module KyckRegistrar
  module Actions
    describe CreateDivision do
      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a competition" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end
      end

      describe "#execute" do
        let(:requestor) { regular_user }
        let(:comp) { create_competition }

        context "user has permission" do
          before(:each) do
            comp.add_staff(requestor, permission_sets:[PermissionSet::MANAGE_COMPETITION])
            CompetitionRepository.persist! comp
          end

          it "should create a new division" do
            result = described_class.new(requestor, comp).execute(name: "Division One", age: "18", gender:"male", kind:"premier")
            comp.divisions.count.should == 1
          end

        end

        context "user does not have permission" do
          it "should raise permission error" do
            expect { described_class.new(requestor, comp).execute({name:"another comp"}) }.to raise_error PermissionsError
          end
        end

      end
    end
  end
end

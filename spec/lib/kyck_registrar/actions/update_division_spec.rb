require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateDivision do

      describe "#new" do
        it "takes a requestor" do
          expect { KyckRegistrar::Actions::UpdateDivision.new }.to raise_error ArgumentError
        end

        it "takes a division" do
          expect { KyckRegistrar::Actions::UpdateDivision.new(User.new) }.to raise_error ArgumentError
        end
      end

      context "when the requestor has manage competition rights" do
        let(:requestor) { regular_user }
        let(:comp) { create_competition(name: "The Comp 1", start_date:DateTime.now, end_date:(DateTime.now+6.months)) }
        let(:div) { create_division_for_competition(comp, name: "Division One", age: "18", gender:"male", kind:"premier") }

        let(:div_attributes) do
          {name: "Division Two", age: "17", gender: "female", kind: "classic a"}
        end

        subject { KyckRegistrar::Actions::UpdateDivision }

        before do
          add_user_to_org(requestor, comp, permission_sets: [PermissionSet::MANAGE_COMPETITION])
        end

        it "should set the new values on the team" do
          changed_div = subject.new(requestor, div).execute div_attributes.merge({"id" => div.id.to_s})
          changed_div.name.should == "Division Two"
          changed_div.age.should == "17"
          changed_div.gender.should == "female"
        end
      end
    end
  end
end


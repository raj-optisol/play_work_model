require 'spec_helper'
require_relative '../../../../app/models/user'
require_relative '../../../../app/models/sanctioning_body'
require_relative '../../../../lib/kyck_registrar/actions/get_sanctioning_bodies'

module KyckRegistrar
  module Actions
    describe GetSanctioningBodies do
      let(:requestor) {regular_user} 
      subject { described_class.new(requestor) }
      let(:sanctioning_body) { create_sanctioning_body }
      describe "initialize" do
        it "takes a requestor" do
          expect{GetSanctioningBodies.new(requestor)}.to_not raise_exception
        end  
      end

      describe "#execute" do
        context "when the requestor has permission" do

          before(:each) do
            sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]}) 
            UserRepository.persist requestor
          end

          it "gets the sanctioning bodies" do
            input = {
              conditions: {id: sanctioning_body.id.to_s},
              permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]
            }
            sbs = subject.execute input
            sbs.first.should_not be_nil
            sbs.first.id.should == sanctioning_body.id
          end

        end

        context "when the requestor is an admin but not on staff" do
          let(:requestor) { admin_user } 
          
          it "gets the sanctioning bodies" do
            input = {
              conditions: {id: sanctioning_body.id.to_s},
              permission_sets: [PermissionSet::MANAGE_SANCTIONING_BODY]
            }
            sbs = subject.execute input
            sbs.first.should_not be_nil
            sbs.first.id.should == sanctioning_body.id
          end
        end
      end
    end
  end
end


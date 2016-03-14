require 'spec_helper'

module KyckRegistrar
  module Actions
    describe RemoveOrganization do

      let(:org) { create_club }
      let(:requestor) { regular_user }
      subject { described_class.new(requestor, org) }

      describe "#initialize" do
        it "takes a requestor and an organization" do
          expect {subject}.to_not raise_error
          subject.org.should == org
        end
      end

      describe "#execute" do 
        context "when the requestor has the required permissions" do
          before(:each) do
            add_user_to_org(requestor, org, {title: 'Regular', permission_sets: [ PermissionSet::MANAGE_ORGANIZATION ]} )
          end

          it "tells the repo to remove the organization" do
            repo = double('repo')
            repo.should_receive(:delete_by_id).with(org.id)
            subject.repository = repo
            subject.execute
          end
        end
      end
    end
  end
end


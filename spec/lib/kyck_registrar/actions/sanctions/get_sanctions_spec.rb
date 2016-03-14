require 'spec_helper'

describe KyckRegistrar::Actions::GetSanctions do

  let(:org) {create_club}
  let(:requestor) {regular_user}
  let(:sanctioning_body) {create_sanctioning_body}

  describe "when a sanctioning_body is supplied" do

     subject {described_class.new(requestor, sanctioning_body).execute({})}
     let(:comp) { create_competition }

     before(:each) do
       add_user_to_org(requestor, sanctioning_body, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_ORGANIZATION]})
       sanctioning_body.sanction(org)
       SanctioningBodyRepository.persist! sanctioning_body
     end

     it "returns the sanctioned orgs" do
       subject.first.sanctioned_item.id.should == org.id
     end

     it "should not return unsanctioned clubs" do
       subject.count.should == 1
     end

     it "should return both the org and competition" do
       sanctioning_body.sanction(comp)
       SanctioningBodyRepository.persist! sanctioning_body
       subject.count.should == 2
     end

     context "when a state is supplied" do

     end
  end
end

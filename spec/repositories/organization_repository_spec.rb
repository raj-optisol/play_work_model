require 'spec_helper'

module OrganizationRepository
  describe ".get_organization_for_obj" do
    let(:club) {create_club}
    context "for a team" do
      let(:team) {create_team_for_organization(club)}

      it "returns the org" do
        org = OrganizationRepository.get_organization_for_obj(team)
        org.kyck_id.should == club.kyck_id
      end
    end
  end
end

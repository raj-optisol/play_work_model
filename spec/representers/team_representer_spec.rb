require 'spec_helper'


describe TeamRepresenter do

  let(:org) { create_club }
  let(:team) { create_team_for_organization(org, {avatar: 'my_avatar'}) }

  describe "to_json" do
    subject { JSON.parse(team.extend(TeamRepresenter).to_json) }

    %w( id name gender age_group avatar avatar_url).each do |attr|
      it "includes the #{attr}" do
        subject[attr].to_s.should == team.send(attr).to_s
      end
    end
  end
end

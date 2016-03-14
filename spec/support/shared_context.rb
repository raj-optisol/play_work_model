shared_context "org, team, roster" do
  let(:org) { create_club}
  let(:team) { create_team_for_organization(org) }
  let(:roster) { create_roster_for_team(team) }
end

shared_context "comp, div, team, roster" do
  let(:team) { create_team }
  let(:roster) { create_roster_for_team(team) }
  let(:comp) { create_competition }
  let(:div) { create_division_for_competition(comp) }
end

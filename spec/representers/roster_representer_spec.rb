require 'spec_helper'
describe RosterRepresenter do
  let(:club) {create_club}
  let(:team) {create_team_for_organization(club)}
  let(:roster) {create_roster_for_team(team)}
  subject{
    p = User.build({first_name: 'Bob', last_name:'Newhart', email: 'bob@newhart.com'})
    UserRepository.persist p
    pl = roster.add_player(p, {position: 'mid'})
    TeamRepository::RosterRepository.persist roster
    roster.extend(RosterRepresenter)
  }
  it "it should include the team" do
    json =  JSON.parse(subject.to_json)
    json["team"]["name"].should == team.name
  end

  it "should include the players" do
    json =  JSON.parse(subject.to_json)

    json["players"][0]["first_name"].should == "Bob"
  end
end

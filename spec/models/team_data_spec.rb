require 'spec_helper'

describe TeamData do
  
  describe "#get_players" do
    let(:team) {create_team}
    let(:official_roster) {create_roster_for_team(team, {official: true})}
    let(:roster) {create_roster_for_team(team, {official: false})}
    let(:user) {regular_user}
    let(:other_user) {regular_user}

    before do
      p1 = official_roster.add_player(user, {position: 'Keeper', jersey_number: 23})
      p1._data.save
      team._data.reload
    end

    it "returns the players for all team rosters" do
      players = team.get_players 
      kyck_ids = players.map {|p| p.user.kyck_id}
      kyck_ids.should include(user.kyck_id)
    end
    
  end
end

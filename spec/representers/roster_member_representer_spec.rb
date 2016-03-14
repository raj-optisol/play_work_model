require_relative '../../app/representers/roster_member_representer'
require_relative '../lib/kyck_registrar/repositories/team_memory_repository'

describe RosterMemberRepresenter, broken: true do
  let(:member) {
    rm = RosterMember.new
    rm.member = Player.new
    rm
  } 

  subject{
    team = Team.build(name: 'The Team')
    roster = team.create_roster({name: 'Rosterphile'})
    roster.extend(RosterRepresenter)
    TeamMemoryRepository.persist team
    roster.stub!(:team) { team}

    p = Player.build(user: UserData.new({first_name: 'Bob', last_name:'Newhart', email: 'bob@newhart.com'}))
    mem = roster.add_member(p, {position: 'mid'})
    mem.extend(RosterMemberRepresenter)
    
  }

  it "should include member type" do
    json =  JSON.parse(subject.to_json)
    json["type"].should == 'Player'  
  end
end

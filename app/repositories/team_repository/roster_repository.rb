# This file is only to hold modules that are contained
# by TeamRepository. No methods for TeamRepository should
# be added here.
#
# The objective is to keep namespaces to two (2) levels, such as
#
# TeamRepository::RosterRepository
#
# as opposed to
#
# OrganizationRepository::TeamRepository::RosterRepository
#
module TeamRepository
  module RosterRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Roster

    def self.get_roster_for_division(team, division)
      query = start_query_with(division)
      query.out(DivisionData.relationship_label_for(:rosters)).as('roster').in(TeamData.relationship_label_for(:rosters)).filter{|it| self.kyck_id == it['kyck_id']}.back('roster')
      query.collect{|c| wrap c.wrapper }
    end

    def self.get_roster_for_competition(comp, team)

      query = start_query_with(comp)
      query.out(CompetitionData.relationship_label_for(:divisions)).out(DivisionData.relationship_label_for(:rosters)).as('roster').in(TeamData.relationship_label_for(:rosters)).filter{|it| team.kyck_id == it['kyck_id']}.back('roster')
      query.collect{|c| wrap c.wrapper }
    end

    def self.get_rosters_for_team(user, team, attrs={}, permissions=[])
      get_items(team, 'Team__rosters', attrs, user, permissions)
    end

    def self.print_roster_info(roster)
      sql = "select expand($union) let $players = (select first_name, last_name, migrated_id, kyck_id, birthdate, in_Card__carded_user as 'cards', traversedVertex(-2) as roster, traversedEdge(-1) as player from (traverse in_plays_for, out from #{roster.id}) where @class='User'), $staff = (select  first_name, last_name, migrated_id, kyck_id, birthdate, in_Card__carded_user as 'cards', traversedVertex(-2) as roster, traversedEdge(-1) as staff  from (traverse in_Team__rosters, in_staff_for, out from #{roster.id}) where @class='User'), $union = unionall($players, $staff)"
      puts sql
      execute_sql(sql).to_a
    end
  end
end

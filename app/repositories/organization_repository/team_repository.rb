# encoding: UTF-8
module OrganizationRepository
  module TeamRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Team

    def self.create_team org, attrs
      team = Team.build(attrs)
      team.organization_id = org.id
      persist team
    end

    def self.destroy_team team
      team.rosters.each do |roster|
        player_rels = roster._data.players_rels.to_a
        player_users = player_rels.map(&:user)
        player_users.each(&:save)
        player_rels.each(&:destroy)
        roster._data.delete
      end
      team.competition_entries.each do |ce|
        ce._data.destroy
      end
      team._data.destroy
    end

    def self.for_user_and_organization(user, org, attrs = {}, permissions = {})
      get_items(org, 'Organization__teams', attrs, user, permissions)
    end

    def self.open_team_for_org!(org)
      sql = 'select from (traverse out_Organization__teams ' \
        "from #{org._data.id}) where open=true "
      team = execute_sql(sql).first
      return team.wrapper.model_wrapper if team

      team = org.create_team(name: 'Open Team', open: true, gender: :coed)
      team.create_roster(name: "Official Roster", official: true)
      persist team
      team
    end

    #
    # Returns the teams for the competition
    #
    # Params:
    #   user: the user to check for given permissions. ignored of permissions is empty
    #   comp: The competition
    #   attrs: Hash with :condtions, :order, :skip, :limit
    #   permssions: Array of permission sets
    def self.get_teams_for_competition(comp, attrs={})
      filters = attrs[:conditions] || {}
      sql = 'select from (traverse in_CompetitionEntry__competition, ' \
        "out_CompetitionEntry__team from #{comp._data.id}) where @class='Team' "
      sql = "#{sql} and #{build_sql_filters(filters)}"
      sql = sql + build_sql_options(attrs)
      gp = execute_sql(sql)
      gp.to_a.map{|c| wrap c.wrapper }
    end

    def self.get_teams_for_player_and_organization(user, club)
      query = start_query_with(user)
      query.outE('plays_for').inV
      query.in(TeamData.relationship_label_for(:rosters))
      query.filter {|it| it['@class'] == 'Team' }
      query.in(OrganizationData.relationship_label_for(:teams))
      query.filter {|o| o['kyck_id'] == club.kyck_id}.back(2)

      query.to_a.uniq.map{|t| wrap t.wrapper}
    end

    def self.get_teams_for_staff_and_organization(user, club)
      query = start_query_with(user)
      query.outE('staff_for').inV.filter { |it| it['@class'] == 'Team' }
      query.in(OrganizationData.relationship_label_for(:teams))
      query.filter { |o| o['kyck_id'] == club.kyck_id }.back(2)

      query.to_a.map { |t| wrap t.wrapper }
    end

    # Returns teams that are a part of a club
    def self.get_current_teams_for_organization(organization, attrs = {})
      filters = attrs[:conditions] || {}

      query = start_query_with(organization)
      today = DateTime.now.to_i

      query.out(OrganizationData.relationship_label_for(:teams))
      query = ConditionBuilder::OrientGraph.build(query, filters)
      query = handle_query_options(query, attrs)

      query.to_a.map{ |c| wrap c.wrapper }
    end

    def self.get_teams_for_organization(org, attrs = {})
      filters = attrs[:conditions] || {}

      query = start_query_with(org)

      query.out(OrganizationData.relationship_label_for(:teams))
      query = ConditionBuilder::OrientGraph.build(query, filters)

      query = handle_query_options(query, attrs)

      query.to_a.map{ |c| wrap c.wrapper }
    end

    def self.teams_summary_for_organization(org)
      grouped_res = { 'U-11 & Below:' => 0,
                      'U-12 to U-19:' => 0,
                      'U-20 to U-22:' => 0,
                      'Adult:' => 0,
                      'Other:' => 0
                      }
      org.teams.each do |team|
        agegroup = team.try(:age_group)
          if !agegroup.present?
              grouped_res['Other:'] += 1
          elsif agegroup == 'Adult'
            grouped_res['Adult:'] += 1
          else
            ag = agegroup[1, agegroup.length - 1]
            if ag.to_i <= 11
              grouped_res['U-11 & Below:'] += 1
            elsif ag.to_i <= 19
              grouped_res['U-12 to U-19:'] += 1
            else
              grouped_res['U-20 to U-22:'] += 1
            end
          end
      end
      # begin
      #   gp = start_query_with(org)
      #   gp.out(OrganizationData.relationship_label_for(:teams))

      #   key_function = KyckPipeFunction.new
      #   key_function.send(:define_singleton_method, :compute) do |it|
      #     agegroup = it['age_group']
      #     if !agegroup
      #       'OTHER'
      #     elsif agegroup == 'adult'
      #       'Adult'
      #     else
      #       ag = agegroup[1, agegroup.length - 1]
      #       if ag.to_i <= 11
      #         'U-11 & Below:'
      #       elsif ag.to_i <= 19
      #         'U-12 to U-19:'
      #       else
      #         'U-20 & Above:'
      #       end
      #     end
      #   end
      #   gp.group_count(grouped_res, key_function)
      #   gp.iterate
      # rescue => e
      #   puts e.inspect
      # end
      grouped_res
    end

    def self.remove_player(team, user)
      player_rel_label = UserData.relationship_label_for(:plays_for)
      gp = start_query_with(team)
      gp.out(TeamData.relationship_label_for(:rosters))
      gp.inE(player_rel_label).outV
      gp.filter { |u| u['kyck_id'] == user.kyck_id }.back(2).remove

      persist team
    end

    def self.current_teams_for_card_request(order)
      sql = 'select from (traverse out_Card__carded_user, out_plays_for, ' \
        'out_staff_for, in, out, in_Team__rosters from (select from card ' \
        "where order_id=#{order.id}) ) where @class='Team'"

      gp = execute_sql sql

      gp.map { |c| wrap c.wrapper }
    end

    def self.wrapper(team)
      wrap team
    end

    def self.touch_players(team_id)
      updatecnt = 0
      begin
        sql = 'select in_plays_for.@rid.asString() ' \
          " from (select expand(out('Team__rosters')) from #{team_id})"

        res = execute_sql(sql).to_a

        if res.count && (players = res[0]['in_plays_for'])
          t = Time.now.utc.to_i
          sql = "update #{players} set updated_at = #{t}"
          updatecnt = execute_sql(sql)
        end
      rescue => e
        puts "exception = #{e.inspect}"
      end
      updatecnt

    end
  end
end

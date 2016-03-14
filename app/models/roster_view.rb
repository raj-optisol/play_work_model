# encoding: UTF-8
class RosterView
  # Takes the results of TeamRepository::RosterRepository.print_roster_info
  # and provides the data needed by the roster pdf
  # roster_hash is an array of staff/players on the roster
  # roster_hash acts just like a hash and looks like:
  #   { "first_name"=>"Hot",
  #     "player"=> { "jersey_number" => jersey number},
  #     "kyck_id"=>"fc212c1a-f639-47b4-aa54-0e9eb92ab467",
  #     "birthdate"=> Date,
  #     "last_name"=>"Rod",
  #     "roster"=> {"name" => roster name},
  #     "cards"=> Single or array of card properties
  #   }
  #
  # team_options
  #   {
  #    name: team_name,
  #    id: team kyck id
  #    age_group: 19
  #    born_after: Date
  #   }
  #
  # organization_options
  #   {
  #     name: org name,
  #     avatar_url: org avatar url
  #   }
  #
  # league_options
  #   {
  #     name: league name
  #   }
  #
  # sanctioned: true if sanctioned. Defaults to false
  def initialize(roster_hash,
                 team_options,
                 organization_options,
                 league_options = {},
                 sanctioned = false)
    @roster_spots = roster_hash
    @org = organization_options
    @league = league_options
    @team = team_options
    @sanctioned = sanctioned
  end

  def sanctioned?
    @sanctioned
  end

  def name
    return 'N/A' unless first_spot && first_spot['name']
    @roster_spots.first['roster']['name']
  end

  def first_spot
    return if @roster_spots.empty?
    @roster_spots.first['roster']
  end

  def club_avatar_url
    @org[:avatar_url]
  end

  def club_name
    @org[:name]
  end

  def club_id
    @org[:id]
  end

  def team_name
    @team[:name]
  end

  def team_id
    @team[:id]
  end

  def team_age_group
    @team[:age_group]
  end

  def team_born_after
    @team[:born_after]
  end

  def league_name
    @league[:name]
  end

  def players
    prune_players.map do |row|
      RosterPlayerRow.new(row, club_id)
    end
  end

  def staff
    prune_staff.map do |row|
      RosterStaffRow.new(row, club_id)
    end
  end

  private

  def prune_staff
    st = @roster_spots.select { |rs| !rs['staff'].blank? }
    st.sort_by do |staff|
      [staff['last_name'], staff['first_name']]
    end
  end

  def prune_players
    ps = @roster_spots.select { |rs| !rs['player'].blank? }
    ps.sort_by do |player|
      [player['last_name'], player['first_name']]
    end
  end
end

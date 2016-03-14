def file_for(str)
  root_dir = ENV["MIGRATE_HOME"] || Rails.root
  File.join(root_dir, str)
end

def benchmark(msg, &block)
  t = Time.zone.now
  log [t.to_s, "START"].join(": ")
  log msg
  yield
  t2 = Time.zone.now
  log [t2.to_s, "END"].join(": ")
  se = t2-t
  m = (se.to_i / 60)
  s = (se.to_i % 60)
  log "[#{msg}][elapsed]#{m}m#{s}s elapsed"
end

def log(msg)
  Rails.logger.info("[migrate][#{Time.zone.now.to_s}]"+msg)
end

require 'gg_migrate'

start_phase = 0
if !ARGV.empty?
  start_phase = ARGV.first.to_i
end


if start_phase <= 1
  benchmark("Member load") { gg_members }
end

if start_phase <= 2
  benchmark("Adding migrated_id index") do
    command = OrientDB::SQLCommand.new("create index User.migrated_id UNIQUE")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Gender + birthday") { gg_player_detail }
end


if start_phase <= 3
  benchmark("Dropping migrated_id index") do
    command = OrientDB::SQLCommand.new("drop index Organization.migrated_id if exists")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Clubs"){ gg_clubs; Oriented.graph.commit }
  benchmark("Adding migrated_id index on Organization") do
    command = OrientDB::SQLCommand.new("create index Organization.migrated_id UNIQUE")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Club sanctioning requests"){ gg_sr }
  benchmark("Club sanctions"){ gg_sanctions }
  benchmark("Club registrars"){ gg_registrars }
  benchmark("Club payment accounts"){ gg_payment_accounts }
end

if start_phase <= 4
  benchmark("Dropping migrated_id index on team") do
    command = OrientDB::SQLCommand.new("drop index Team.migrated_id if exists")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Teams") { gg_teams }
  benchmark("Adding migrated_id index on Team") do
    command = OrientDB::SQLCommand.new("create index Team.migrated_id UNIQUE")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Teams and staff") { gg_team_staff }
end

if start_phase <= 5
  benchmark("Teams, clubs, and seasons") { gg_teams_seasons }
end

if start_phase <= 6
  benchmark("Leagues"){ gg_leagues }
  benchmark("League sanctioning"){ gg_league_sanction_request }
  benchmark("Clubs and leagues"){ gg_club_league }
  benchmark("Club processors"){ gg_card_processor }
end

if start_phase <= 7
  benchmark("Cards and users"){ gg_cards_with_users }
  benchmark("Adding migrated_id index on Organization") do
    command = OrientDB::SQLCommand.new("create index Card.migrated_id NOTUNIQUE")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Cards and clubs"){ gg_cards_with_orgs }
  benchmark("Cards and sb"){ gg_cards_with_sb }
end


# Addresses
if start_phase <= 8
  benchmark("Address load"){ AddressMigrator.process_file(file_for("csv/address.csv")) }
  benchmark("Adding migrated_id index on Location") do
    command = OrientDB::SQLCommand.new("create index Location.migrated_id UNIQUE")
    Oriented.connection.java_connection.command(command).execute
  end
  benchmark("Address and clubs"){ ClubMigrator.associate_addresses(file_for("csv/club.csv")) }
  benchmark("Member and addresses"){ MemberMigrator.associate_addresses(file_for("csv/member.csv")) }

end 

# # Tournaments
# benchmark("[Step 7] Tournaments and clubs") do
#   log("Loading tournaments")
#   TournamentMigrator.process_file(file_for("csv/tournament.csv"), resume_type: "Tournament")
#   log("Associating tournaments with clubs")
#   TournamentMigrator.associate_club(file_for("csv/tournament.csv"))
# end if start_phase <= 7

Oriented.graph.raw_graph.declare_intent(nil)

if start_phase <= 9
  benchmark("Create account file for auth, set emails"){ gg_account_creation }
end 


%w{ Team Card }.each do |term|
  benchmark("Dropping migrated_id index on #{term}") do
    command = OrientDB::SQLCommand.new("drop index #{term}.migrated_id")
    Oriented.connection.java_connection.command(command).execute
  end
end



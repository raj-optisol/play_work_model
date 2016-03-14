def gg_clubs(with_intent= false, delete_mr=false)

  # 66 seconds using remote plocal using java api committing transactions every 100

  if delete_mr
    cmd = OrientDB::SQLCommand.new('truncate class Organization')
    Oriented.graph.command(cmd).execute
        
    MigratedRecord.where(original_type: 'Club').delete_all
    DuplicateMigratedRecord.delete_all
    MigratedRecordAssociation.delete_all
  end

  f = File.join(Rails.root, 'csv/club.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end

  Benchmark.measure do
    ClubMigrator.process_file(f, resume_type: 'Club')
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
end

def gg_club_league
  
#   cmd = OrientDB::SQLCommand.new('select from Organization where league_id is not null')
#   
# cmd = OrientDB::SQLCommand.new('select from competition where migrated_id in (select league_id from Organization where league_id is not null)')
# comps = Oriented.connection.java_connection.command(cmd).execute
  
  f = File.join(Rails.root, 'csv/club.csv')  
  Benchmark.measure do
    ClubMigrator.add_league_id(f)    
  end
end

def gg_card_processor(delete=false)
  
  #28 seconds using embed plocal with sql commiting every 200
    
  if delete
    cmd = OrientDB::SQLCommand.new("update (select expand(in(Card__processor)) from Competition where in_Card__processor is not null) remove out_Card__processor")
    r = Oriented.graph.command(cmd).execute    
      
    cmd = OrientDB::SQLCommand.new("update (select from Competition where in_Card__processor is not null) remove in_Card__processor")
    r = Oriented.graph.command(cmd).execute
  end
  

  f = File.join(Rails.root, 'csv/passcard_request.csv')  
  Benchmark.measure do  
      PasscardRequestMigrator.update_processor(f)
  end
end

def gg_members(with_intent= true, delete=false)

  #Took 14minutes using plocal:file database with java_api latest build
  #Took 8.2 minutes using plocal:file database with sql insert latest build  
  
  # 410 seconds (6.8min) using remote plocal with sql insert committing transactions every 500
  
  # 380 seconds (6.3min) using embedded plocal with sql insert committing transactions every 500  
  

  
  if delete
    Oriented.graph.autoStartTx = false
    Oriented.graph.commit
    cmd = OrientDB::SQLCommand.new('truncate class User')
    Oriented.graph.command(cmd).execute    
    Oriented.graph.autoStartTx = true
    Oriented.graph.commit
    
    MigratedRecord.where(original_type:'Member').delete_all
    # DuplicateMigratedRecord.delete_all
    # MigratedRecordAssociation.delete_all
  end

  f = File.join(Rails.root, 'csv/member.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  t = Benchmark.measure do
    MemberMigrator.process_file(f, resume_type: "Member")
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
  
  t
end

def gg_member_addresses(with_intent= true, delete=false)
  
  if delete
    # Oriented.graph.autoStartTx = false
    # Oriented.graph.commit
    # cmd = OrientDB::SQLCommand.new('truncate class User')
    # Oriented.graph.command(cmd).execute    
    # Oriented.graph.autoStartTx = true
    # Oriented.graph.commit
    # 
    # MigratedRecord.where(original_type:'Member').delete_all
    # DuplicateMigratedRecord.delete_all
    # MigratedRecordAssociation.delete_all
  end

  f = File.join(Rails.root, 'csv/member.csv')
  t = Benchmark.measure do
    MemberMigrator.associate_addresses(f, resume_type: "Member")
  end
  
  t
end


def gg_account_creation(delete=false)
  
  # cmd = OrientDB::SQLCommand.new("select from index:User.email where key = 'barberio@optonline.net'")
  # r = Oriented.graph.command(cmd).execute
  
  if delete
    Oriented.graph.autoStartTx = false
    Oriented.graph.commit
    cmd = OrientDB::SQLCommand.new('update (select from User where in_User__owners is not null) remove in_User__owners')  
    Oriented.graph.command(cmd).execute         
    cmd = OrientDB::SQLCommand.new('update (select from User where out_User__owners is not null) remove out_User__owners') 
    Oriented.graph.command(cmd).execute     
    
    Oriented.graph.autoStartTx = true
    Oriented.graph.commit
    
    # begin
    #       cmd = OrientDB::SQLCommand.new('update (select from User where in_User__owners is not null) remove in_User__owners')  
    #       Oriented.graph.command(cmd).execute         
    #       cmd = OrientDB::SQLCommand.new('update (select from User where out_User__owners is not null) remove out_User__owners') 
    #       Oriented.graph.command(cmd).execute
    #     rescue => e
    #       puts e.inspect
    #     end
  end

  f = File.join(Rails.root, 'csv/member_login.csv')
  Benchmark.measure do
    AccountCreationMigrator.process_file(f)
  end
  
end

def gg_player_detail(with_intent=true, delete=false)
  f = File.join(Rails.root, 'csv/player_detail.csv')

  # took 1398 seconds (23min) using remote plocal graph with sql and no transactions
  
  Oriented.graph.autoStartTx = false
  Oriented.graph.commit
  
  if delete
    # update user staff for property
    cmd = OrientDB::SQLCommand.new('update season remove in_plays_for')
    Oriented.graph.command(cmd).execute
    
    cmd = OrientDB::SQLCommand.new('update roster remove in_plays_for')
    Oriented.graph.command(cmd).execute
    
    cmd = OrientDB::SQLCommand.new("update (select expand(out) from plays_for) remove out_plays_for")
    Oriented.graph.command(cmd).execute      
    # delete staff_for edge
    cmd = OrientDB::SQLCommand.new("truncate class plays_for")
    Oriented.graph.command(cmd).execute          
    Oriented.graph.commit
  end
  
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  t = Benchmark.measure do
    PlayerDetailMigrator.process_file(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
  
  Oriented.graph.autoStartTx = true
  Oriented.graph.commit
  
  t

end

def gg_player_kyck_id()
  # 1678 seconds (28min) using embedded plocal sql
  
  Oriented.graph.autoStartTx = false
  Oriented.graph.commit
  t = Benchmark.measure do    
    PlayerDetailMigrator.update_player_kyck_id()
  end
  
  Oriented.graph.autoStartTx = true
  Oriented.graph.commit
  
  t
end

# def gg_rosters(with_intent=true)
#   f = File.join(Rails.root, 'csv/player_detail.csv')
#   if with_intent
#     i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
#     Oriented.graph.raw_graph.declare_intent(i)
#   end
#   Benchmark.measure do
#     PlayerDetailMigrator.place_on_rosters(f)
#     Oriented.graph.raw_graph.declare_intent(nil) if with_intent
#   end
# end


def gg_sr(with_intent=true, delete=false)

  # 21 seconds using remote plocal with java api commiting every 200 
  #  67 seconds using remote plocal graph and with sql call and committing transactions every 200
  
  # 8 seconds using embedded plocal graph with java api and commit every 200
  
  if delete
    cmd = OrientDB::SQLCommand.new('truncate class SanctioningRequest')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update sanctioningbody remove in_target')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update organization remove in_on_behalf_of')
    Oriented.connection.java_connection.command(cmd).execute
  end

  f = File.join(Rails.root, 'csv/club.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    ClubMigrator.sanctioning_requests(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
end

def gg_sanctions(delete=false)
  
  # 29 seconds using remote plocal graph with sql  
  # 11 seconds using embedded plocal graph with sql 
  
  Oriented.graph.autoStartTx = false
  Oriented.graph.commit
  if delete
    cmd = OrientDB::SQLCommand.new('truncate class sanctions')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update sanctioningbody remove out_sanctions')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update organization remove in_sanctions')
    Oriented.connection.java_connection.command(cmd).execute
  end
  t = Benchmark.measure do
    ClubMigrator.create_sanctions
  end
  
  Oriented.graph.autoStartTx = true
  Oriented.graph.commit
  
  t
end

def gg_payment_accounts(delete=false)
  if delete
    AccountTransactionData.delete_all
    PaymentAccountData.delete_all
  end
  f = File.join(Rails.root, 'csv/club.csv')
  Benchmark.measure do
    ClubMigrator.create_payment_accounts(f)
  end
end

def gg_registrars(with_intent=true, delete=false)


  # took 20 seconds using remote plocal with java api committing every 500 
  # 11 seconds using embed plocal with java api committing every 200  

  if delete
    puts "deleting"

    # update user staff for property
    cmd = OrientDB::SQLCommand.new("update (select expand(out) from (select from (traverse in_staff_for from Organization) where @class = 'staff_for')) remove out_staff_for")
    Oriented.connection.java_connection.command(cmd).execute      
    # delete staff_for edge
    cmd = OrientDB::SQLCommand.new("delete from (select from (traverse in_staff_for from Organization) where @class = 'staff_for')")
    Oriented.connection.java_connection.command(cmd).execute        
    # remove organization staff_for property
    cmd = OrientDB::SQLCommand.new("update Organization remove in_staff_for")
    Oriented.connection.java_connection.command(cmd).execute

    puts "done deleting"
  end
  f = File.join(Rails.root, 'csv/club.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    ClubMigrator.associate_registrars(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
end

def gg_teams(with_intent=true, with_delete=false)

  # 104 seconds with remote plocal graph using java api and commit transactions every 500 
  
  # Oriented.graph.autoStartTx = false
  # Oriented.graph.raw_graph.transaction.close
  # Oriented.graph.commit
  # Oriented.graph.raw_graph.set_retain_records(false)
  
  if with_delete
    
    cmd = OrientDB::SQLCommand.new("update Team remove in_staff_for")
    Oriented.connection.java_connection.command(cmd).execute
        
    cmd = OrientDB::SQLCommand.new('truncate class Team')
    Oriented.graph.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('truncate class Roster')
    Oriented.graph.command(cmd).execute
    
    cmd = OrientDB::SQLCommand.new('truncate class CompetitionEntry')
    Oriented.graph.command(cmd).execute    
    MigratedRecord.where(original_type:'Team').delete_all
    Oriented.graph.commit
  end

  f = File.join(Rails.root, 'csv/team.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    TeamMigrator.process_file(f, resume_type: 'Team')
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end

end

def gg_teams_seasons(with_intent=true, with_delete=false)
  
  # 140 seconds with remote plocal graph using java_api committing every 500 
  # 187 seconds using embed plocal with java api committing every 200  
  
  if with_delete
    cmd = OrientDB::SQLCommand.new('truncate class Season')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update team remove in_Season__teams')
    Oriented.connection.java_connection.command(cmd).execute
    cmd = OrientDB::SQLCommand.new('update organization remove out_Organization__seasons')
    Oriented.connection.java_connection.command(cmd).execute
  end

  f = File.join(Rails.root, 'csv/team.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    TeamMigrator.process_clubs(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
end

def gg_card_products( with_delete=false)
  
  if with_delete
    CardProductData.delete_all
  end
  f = File.join(Rails.root, 'csv/team.csv')
  Benchmark.measure do
    TeamMigrator.card_products(f)
  end
end

def gg_team_staff(with_intent=true, delete=false)
  
  # 170 seconds using remote plocal with java api committing every 500
  # 105 seconds using embed plocal with java api committing every 200
  
  if delete
    # update user staff for property
    cmd = OrientDB::SQLCommand.new("update (select expand(out) from (select from (traverse in_staff_for from Team) where @class = 'staff_for')) remove out_staff_for")
    Oriented.connection.java_connection.command(cmd).execute      
    # delete staff_for edge
    cmd = OrientDB::SQLCommand.new("delete from (select from (traverse in_staff_for from Team) where @class = 'staff_for')")
    Oriented.connection.java_connection.command(cmd).execute        
    # remove organization staff_for property
    cmd = OrientDB::SQLCommand.new("update Team remove in_staff_for")
    Oriented.connection.java_connection.command(cmd).execute

  end
  f = File.join(Rails.root, 'csv/team.csv')
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    TeamMigrator.associate_staff(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
  
end

def gg_leagues(delete=false)
  
  # 4.8 seconds using remote plocal graph with java api and committing every 200  (only 248 records)

  if delete
    
    
    # cmd = OrientDB::SQLCommand.new('update (select expand(out(Card__carded_user)) from Card) remove in_Card__carded_user')
    # Oriented.connection.java_connection.command(cmd).execute

  end  
  
  f = File.join(Rails.root, 'csv/league.csv')
  Benchmark.measure do
    LeagueMigrator.process_file(f, resume_type:'League')
  end
  
end

def gg_league_sanction_request(delete=false)
  
  #2.6 seconds using remote plocal graph with java_api 
  if delete
    
  end
  
  f = File.join(Rails.root, 'csv/league.csv')
  Benchmark.measure do
    LeagueMigrator.create_sanctioning_requests()
    Oriented.graph.commit    
  end
  
end

def gg_sanction_leagues(delete=false)
  
  # 6 seconds using remote plocal graph with sql 
  
  if delete
    # cmd = OrientDB::SQLCommand.new('truncate class sanctions')
    # Oriented.connection.java_connection.command(cmd).execute
    # cmd = OrientDB::SQLCommand.new('update sanctioningbody remove out_sanctions')
    # Oriented.connection.java_connection.command(cmd).execute
    # cmd = OrientDB::SQLCommand.new('update organization remove in_sanctions')
    # Oriented.connection.java_connection.command(cmd).execute
    # 
    # cmd = OrientDB::SQLCommand.new('create edge sanctions from (select from sanctioningbody) to (select from (traverse sanctioningrequest.out_on_behalf_of from sanctioningrequest ) where @class = "Competition")')
    # Oriented.connection.java_connection.command(cmd).execute
  end
  
  f = File.join(Rails.root, 'csv/league.csv')
  Benchmark.measure do
    LeagueMigrator.create_sanctions()
    Oriented.graph.commit
  end
  
end

def gg_league_address()
  f = File.join(Rails.root, 'csv/league.csv')
  t = Benchmark.measure do
    LeagueMigrator.associate_addresses(f)
  end
  
  t
end

# in_Card__sanctioning_body
# create edge Card__sanctioning_body from (select @ri from Card where @rid >= #23:0 and @rid < #23:15000) to #12:0

def gg_cards_with_users(with_intent= true, delete=false)
  
  # 627 seconds (10.4min) using remote plocal graph with java api committing every 200   1 year  
  #8.2 minutes using embedded plocal with no transactions  1 year  
  # 1147 sec (19 min) using embedded plocal with java api committing transactions every 200  and 3 years of cards
  # 3279.737000
  
  # curl https://www.strongspace.com/shared/t3lw60uz90 -o csv/member_passcard_request.csv
  # Oriented.graph.autoStartTx=false
  # Oriented.graph.commit
  
  f = File.join(Rails.root, 'csv/member_passcard_request_3yr.csv')
  # f = File.join(Rails.root, 'csv/member_passcard_request.csv')  
  if delete
    cmd = OrientDB::SQLCommand.new('update (select expand(out(Card__carded_user)) from Card) remove in_Card__carded_user')
    Oriented.graph.command(cmd).execute
    
    cmd = OrientDB::SQLCommand.new('truncate class Card')
    Oriented.graph.command(cmd).execute
    
    Oriented.graph.commit
    #update (select expand(out(Card__carded_user)) from Card) remove in_Card__carded_user
    # cmd = OrientDB::SQLCommand.new('update Card remove out_Card__carded_user')
    # Oriented.connection.java_connection.command(cmd).execute
    # 
    # cmd = OrientDB::SQLCommand.new('update user remove in_Card__carded_user')
    # Oriented.connection.java_connection.command(cmd).execute
  end
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  t = Benchmark.measure do
    MemberPasscardRequestMigrator.process_file(f)
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent
  end
  
  # Oriented.graph.autoStartTx=true
  # Oriented.graph.commit
  t
end

# load 'gg_migrate.rb'
# begin
#   gg_cards_with_orgs(false, true)
# rescue => e
#   puts e.inspect
# end

def gg_cards_with_orgs(with_intent= true, delete=false)
  
  # 216 seconds using remote plocal graph with both java_api and sql committing transaction every 200
  
  if delete
    # cmd = OrientDB::SQLCommand.new('update (select expand(out(Card__carded_for)) from Card) remove in_Card__carded_for')
    cmd = OrientDB::SQLCommand.new('update Organization set in_Card__carded_for=null')    
    Oriented.graph.command(cmd).execute
    
    cmd = OrientDB::SQLCommand.new('update Card remove out_Card__carded_for')
    Oriented.graph.command(cmd).execute

  end
  
  f = File.join(Rails.root, 'csv/passcard_request_3yr.csv')
  # f = File.join(Rails.root, 'csv/passcard_request.csv')  
  if with_intent
    i=OrientDB::CORE::intent::OIntentMassiveInsert.new()
    Oriented.graph.raw_graph.declare_intent(i)
  end
  Benchmark.measure do
    PasscardRequestMigrator.process_file(f)
    Oriented.graph.commit    
    Oriented.graph.raw_graph.declare_intent(nil) if with_intent

  end
  
end
def gg_cards_with_sb(delete=false)
  
  # 36 seconds using embed:plocal graph sql no transactions
  
  Oriented.graph.autoStartTx = false
  Oriented.graph.commit
  
  if delete
    cmd = OrientDB::SQLCommand.new('update Card remove out_Card__sanctioning_body')
    Oriented.graph.command(cmd).execute
    Oriented.graph.commit
    puts "Done update Card"
    
    cmd = OrientDB::SQLCommand.new('update SanctioningBody remove in_Card__sanctioning_body')
    Oriented.graph.command(cmd).execute
    Oriented.graph.commit    
    puts "Done update SanctioningBody"
    
  end

  Benchmark.measure do    
    PasscardRequestMigrator.add_sanctioning_body_to_cards
    Oriented.graph.autoStartTx = true
    Oriented.graph.commit    
  end
end

def gg_previous_cards()

  Benchmark.measure do    
    PasscardRequestMigrator.setup_previous_cards
  end

end

def gg_locations(delete=false)
  if delete
    cmd = OrientDB::SQLCommand.new('update (select from Organization where out_locations is not null) remove out_locations')
    Oriented.graph.command(cmd).execute
            
    cmd = OrientDB::SQLCommand.new('truncate class Location')
    Oriented.graph.command(cmd).execute    
  end

  f = File.join(Rails.root, 'csv/address.csv')
  Benchmark.measure do
    AddressMigrator.process_file(f, resume_type: "Address")
  end
end

def gg_club_locations(delete=false)
  if delete
    cmd = OrientDB::SQLCommand.new('select from Organization where out_locations is not null')
    Oriented.graph.command(cmd).execute
  end

  f = File.join(Rails.root, 'csv/club.csv')
  Benchmark.measure do
    ClubMigrator.associate_addresses(f)    
  end
  
end

def gg_update_sanctions
  cmd = OrientDB::SQLCommand.new('update sanctions set status= "active"')
  Oriented.graph.command(cmd).execute
  Oriented.graph.commit
end

#    ClubMigrator.associate_addresses(file_for("csv/club.csv"))    

def create_index(sql)
  Oriented.graph.autoStartTx = false
  Oriented.graph.commit
  cmd = OrientDB::SQLCommand.new(sql)
  Oriented.graph.command(cmd).execute  
  Oriented.graph.autoStartTx = true
  Oriented.graph.commit
end

def run_migrations
  MigratedRecord.delete_all
  DuplicateMigratedRecord.delete_all
  MigratedRecordAssociation.delete_all
   
  # Oriented.graph
  
  # create_index('drop index User.email')
  # puts "Removed User email unique index"
    
  gg_members
  puts "Done with Members"
  
  create_index('create index User.migrated_id on User (migrated_id) unique')
  puts "Created User migrated_id unique index"
    
  gg_clubs
  puts "Done with Clubs"  
  
  create_index('create index Organization.migrated_id on Organization (migrated_id) unique')
  puts "Created Organization migrated_id unique index"
  
  # create_index('create index User.email on User (email) unique')
  # puts "Created User email unique index"
  
  gg_account_creation(true)
  puts "created accounts file and updated emails"
  
  gg_leagues
  puts "created league"
  
  create_index('create index Competition.migrated_id on Competition (migrated_id) unique')
  puts "created league migrated_id index"  
  
  gg_teams  
  puts "created team"  
  
  create_index('create index Team.migrated_id on Team (migrated_id) unique')
  puts "created team migrated_id index"    
  
  gg_teams_seasons
  puts "created team seasons"  
  
  gg_registrars
  puts "created org registrars"  
  
  gg_team_staff
  puts "created team staff"  
  
  gg_player_detail
  puts "updated user details and add players to rosters/seasons"  
  
  gg_player_kyck_id
  puts "update player kyck_ids"
  
  gg_sr
  puts "created org santioning request"  
  
  gg_sanctions()
  puts "created org sanctions"  
  
  gg_league_sanction_request
  puts "created league sanctioning request"  
  
  gg_sanction_leagues  
  puts "created league sanctions"  
  
  # BEGIN CARDS
  
  gg_cards_with_users
  puts "created cards and added users"    
  
  create_index('create index Card.migrated_id on Card (migrated_id) notunique')
  puts "created cards migrated_id not unique index"    
  
  
  gg_cards_with_orgs  
  puts "added organizations to cards"     
  
  gg_cards_with_sb 
  puts "added sanctioning body to cards"       
  
  gg_club_league
  puts "league id on org"
  
  gg_card_processor
  puts "added league processor to cards"
  
  gg_previous_cards
  puts "added previous cards"
  
  # END CARDS
  
  gg_locations
  puts "Added locations"
  
  create_index('create index Location.migrated_id on Location (migrated_id) unique')
  puts "Added location migrated index"
    
  gg_club_locations
  puts "Added locations to Clubs"
  
  gg_payment_accounts(true)
  puts "Added payment account balance to Organizations"

  # Adds sales reps, admins, and state assignments
  UscsStaffMigrator.process
  # Adds logins in auth for everybody
  UscsStaffMigrator.process_staff_file(File.join(Rails.root, "csv/cms_user.csv"))

  gg_league_address
  puts "Added League Addresses"

  gg_member_addresses
  puts "Added Member Addressess"

  
  PasscardRequestMigrator.open_players
  puts "Added open players"
  PasscardRequestMigrator.open_staff
  puts "Added open staff"
end


def add_indices 
  # create_index('create index cards on Card (status, kind, expires_on) notunique')
  # add composite index for card lookups
  
  # create_index('create index users on Card (first_name, last_name, expires_on) notunique')
  
end

def associate_carded_staff_to_season
  #select * from Card let $st = (select @rid from $current.out_Card__carded_user where out_staff_for is null) where kind = 'staff' and out_Card__carded_for is not null and $st.size() > 0
end

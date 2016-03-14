def migrate_fixture(str, spec = nil)
  YAML.load(File.open(File.join(File.dirname(__FILE__), "../migrate/fixtures/#{str}.yml")))[(spec||str)] 
end

def fixture_migration_root
  File.join(Rails.root, "spec/fixtures")
end

def create_spec_location(id)
  l = create_location
  MigratedRecord.create(original_type: "Address", original_id: id, kyck_id: l.kyck_id)
  l
end

def create_spec_club(id, opts = {})
  club = create_club(opts)
  MigratedRecord.create(original_type: "Club", original_id: id, kyck_id: club.kyck_id)
  club
end

def create_spec_team(id, club_id=nil)
  cid = (club_id || rand(10000)+1)
  club = create_spec_club(cid)
  MigratedRecord.create(original_type: "Club", original_id: cid, kyck_id: club.kyck_id)
  season = create_season_for_organization(club)
  team = create_team_for_organization(club)
  team.create_roster(name:"Official Roster", official:true)
  OrganizationRepository::TeamRepository.persist!(team)
  MigratedRecord.create(original_type: "Team", original_id: id, kyck_id: team.kyck_id)
  team
end

def create_spec_user(id)
  user = regular_user
  MigratedRecord.create(original_type: "Member", original_id: id, kyck_id: user.kyck_id)
  user
end

def create_duplicate_record(mr, new_id)
  DuplicateMigratedRecord.create(migrated_record_id: mr.id, additional_id: new_id)
end

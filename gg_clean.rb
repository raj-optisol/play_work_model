def gg_clean_all

  offset=0
  while offset < 1300000
    bcs = gg_look_for_bad_cards(200000, offset)
    gg_process_users(bcs)
    puts "#{offset} done"
    offset = offset + 200000
  end
end

# Probably shouldn't try limit > 200000
# at least, my mac couldn't handle more
def gg_look_for_bad_cards(limit=10000, offset=0)
  bad_users = []
  UserRepository.find_by_attrs(limit: limit, offset:offset).each do |u|
    groups = gg_group_cards_for_user(u)
    bad_users << u  if groups.values.any? {|v| v.size > 1} || groups.keys.any? {|k| k =~ /^NULL/}
  end

  bad_users
end

def gg_process_users(users)
  cnt=0
  Oriented.graph.commit
  Oriented.graph.autoStartTx = false
  users.each do |u|
    begin
    # Delete duplicate cards 
    gg_delete_duplicate_cards_for_user(u)
    gg_line_up_cards_for_user(u)
    Oriented.graph.commit
    puts "** DONE processing #{u.kyck_id}"
    rescue => ex
      puts "Error #{u.kyck_id}"
      Oriented.close_connection
      raise
    end
  end
  Oriented.graph.commit
  Oriented.graph.autoStartTx = true
end

# This takes tthe output of gg_group_cards_for_user
# and deletes all but one card in each group
def gg_delete_duplicate_cards_for_group(group_of_cards)
  card_to_keep = group_of_cards.shift
  puts "keeping #{card_to_keep.kyck_id}"
  group_of_cards.each do |c|
    puts "deleting #{c.kyck_id}"
    res = Benchmark.measure do
      Oriented.graph.remove_vertex(c._data.__java_obj)
    end
    puts "deleted #{c.kyck_id}"
    Oriented.graph.commit
    puts res
  end
end

def gg_delete_duplicate_cards_for_user(user)
  puts "*** Deleting duplicate cards for #{user.full_name}"
  groups = gg_group_cards_for_user(user)
  groups.values.each do |cs|
    gg_delete_duplicate_cards_for_group(cs)
  end
  user._data.reload
  puts "#{user.full_name} now has #{user.cards.count} cards"
  puts "******"
end

def gg_line_up_cards_for_user(user)

  puts "*** Lining up cards for #{user.full_name}"
  grps = gg_group_cards_by_org_for_user(user)
  grps.each do |g, cards| 
    puts cards.count
    cards = cards.sort {|c1,c2| c1.migrated_id <=>c2.migrated_id}.reverse
    puts cards.count
    current_card = cards.shift._data

    cards.each do |c|
      puts "current_card = #{current_card.kyck_id}"
      nc = c._data
      gg_line_up_cards(nc, current_card)
      current_card= nc
      puts "current_card = #{c.kyck_id}"
    end
  end
  puts "*** Done Lining up cards for #{user.full_name}"

end

def gg_line_up_cards(prev_card, next_card)
  puts "Making #{next_card.kyck_id} the next card for #{prev_card.kyck_id}"
  prev_card.reload
  puts 1
  prev_card.next = next_card
  puts 2
  prev_card.carded_for_rel.try(:delete)
  puts 3
  prev_card.carded_user_rel.try(:delete)
  puts 5
  prev_card.status = "expired"
  puts 6
  Oriented.graph.commit
  puts 7
  prev_card.save
  puts "** Cards lined up"
end

def gg_card_stats_for_user(user)

  card_stats = {
    clubs: {},
    kinds: {},
    statuses:{}
  }
  user.cards.each do |c|
    org_id = (c.carded_for ? c.carded_for.kyck_id : "NULL") 
    org_name = (c.carded_for ? c.carded_for.name : "NULL") 
    card_stats[:clubs][org_id] ||=[]
    card_stats[:clubs][org_id] << org_name
    card_stats[:kinds][c.kind] ||=0
    card_stats[:kinds][ c.kind ] = card_stats[:kinds][ c.kind ] + 1
    card_stats[:statuses][c.status] ||=0 
    card_stats[:statuses][c.status] = card_stats[:statuses][c.status] + 1
  end

  card_stats
end

def gg_group_cards_for_user(user)

  puts "grouping"
  user.cards.group_by do |c|
    puts c.kyck_id
    puts c.carded_for.inspect
    org_id= c.carded_for.try(:kyck_id) || "NULL"
    "#{org_id}__#{c.kind}-#{c.status}-#{c.migrated_id}"
  end

end

# Groups cards for the user by 
# org_id, kind, and status
# if the card has no carded_for, we default the org
# to the first cards org
def gg_group_cards_by_org_for_user(user)

  default_org =  user.cards.select {|c| c.carded_for}.first.try(:carded_for) ||
    gg_get_org_for_user(user)
  unless default_org
    puts "NO ORG for #{user.kyck_id}"
    return []
  end
  default_org_id = default_org.kyck_id



  user.cards.group_by do |c|
    org_id= c.carded_for.try(:kyck_id) || default_org_id
    unless c.carded_for
      c._data.carded_for = default_org._data 
      c._data.save
    end

    "#{org_id}__#{c.kind}-#{c.status}"
  end

end

def gg_get_org_for_user(user)
 
  #try plays for first
  if user.plays_for.any?
    user.plays_for.first.organization
  elsif user.staff_for.any?
    s = user.staff_for.first
    case s
    when Organization
      s
    else
      s.organization
    end
  end
end


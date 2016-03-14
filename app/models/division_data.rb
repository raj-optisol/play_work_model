class DivisionData < BaseModel::Data

  has_one(:competition).from(CompetitionData, :divisions)
  
  has_n(:entries).from(CompetitionEntryData, :division)    
  
  property :name, :age, :gender, :kind
  property :is_open, :type => :boolean, default: true   
  property :roster_lock_date, type: Fixnum
  property :locked, :type => :boolean, default:false

  def add_roster(roster)
    rosters << roster._data 
    roster
  end

  def remove_roster(roster)
    rel = rosters_rels.to_other(roster._data).first
    rel.delete if rel
  end

  def lock_rosters
    self.rosters.each do |roster|
      roster.locked =true
      roster.save
    end
  end

  def unlock_rosters
    self.rosters.each do |roster|
      roster.locked = false
      roster.save
    end
  end

  def viewable_by?(user)
    return true unless self.competition
    return self.competition.viewable_by?(user)
  end
end

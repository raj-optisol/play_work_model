class RosterMemoryRepository

  def self.all
    rosters
  end

  def self.persist(roster)
    roster.id = rosters.count if roster.id.nil?

    rosters << roster

    roster 
  end

  def self.find(id)

    rosters.select do |u|
      u.id == id
    end

    rosters.first
  end


  private

  def self.rosters
    @rosters ||= []
  end
end


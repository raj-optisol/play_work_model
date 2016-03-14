module TeamMemoryRepository
 

  def self.persist(team)
    team.id = teams.count if team.id.nil?

    teams << team

    team.rosters.each do |r|
      RosterMemoryRepository.persist r
    end

    team
  end

  def self.get(id)

    teams.select do |u|
      u.id == id
    end

    teams.first
  end

  private

  def self.teams
    @teams ||= [] 
  end

  module RosterMemoryRepository
    def self.persist(roster)
      roster.id = rosters.count if roster.id.nil?

      rosters << roster

      roster.players.each do |m|
        PlayerMemoryRepository.persist m
      end

      roster
    end

    def self.get(id)

      rosters.select do |u|
        u.id == id
      end

      rosters.first
    end

    private

    def self.rosters
      @rosters ||= [] 
    end

    module RosterMemberMemoryRepository
      def self.persist(member)
        member.id = members.count if member.id.nil?

        members << member

        member
      end

      def self.get(id)

        members.select do |u|
          u.id == id
        end

        members.first
      end

      private

      def self.members
        @members ||= [] 
      end

    end

  end
end

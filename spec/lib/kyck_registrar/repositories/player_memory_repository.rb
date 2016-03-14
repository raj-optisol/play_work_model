class PlayerMemoryRepository

  def self.all
    players
  end

  def self.persist(player)
    player.id = players.count if player.id.nil?

    players << player

    player 
  end

  def self.find(id)

    players.select do |u|
      u.id == id
    end

    players.first
  end


  private

  def self.players
    @players ||= []
  end
end


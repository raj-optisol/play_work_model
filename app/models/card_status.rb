class CardStatus
  attr_accessor :user, :card_type, :entities

  def initialize(user)
    @user = user
    @card_type = user.plays_for.count > 0 ? "player" : "staff"
    case @card_type
    when "player"
      @entities = user.plays_for.map {|p| p.is_a?(Roster) ? p.team : nil }
    else
      @entities = user.staff_for.map { |s| s.is_a?(Team) ? p : nil }
    end

    @entities = [] unless @entities
    @entities.compact!
  end
end

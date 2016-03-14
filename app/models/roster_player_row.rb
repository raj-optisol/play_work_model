# encoding: UTF-8
class RosterPlayerRow
  include RosterRowMethods
  # Takes a player row from RosterView
  def initialize(row, club_id)
    @row = row
    @club_id = club_id
  end

  def player_id
    @row['migrated_id'] || @row['kyck_id'][0..10]
  end

  def jersey_number
    @row['player']['jersey_number']
  end

  def birthdate
    bd = card_or_player_value_for('birthdate')
    return if bd.blank?
    Time.at(bd.getTime / 1000)
  end
end

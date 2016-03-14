# encoding: UTF-8
module RosterRowMethods
  def first_name
    card_or_player_value_for('first_name')
  end

  def last_name
    card_or_player_value_for('last_name')
  end

  def card_expiration
    return unless first_card
    Time.at(first_card['expires_on'])
  end

  def cards
    return @cards if @cards
    @cards = cards_for_club.select { |c| c['status'] == 'approved' }
    @cards.sort! { |a, b| b['expires_on'] <=> a['expires_on'] }
    @cards
  end

  private

  def first_card
    return unless cards.any?
    cards.first
  end

  def cards_for_club
    wrap_cards.select do |c|
      next unless c['out_Card__carded_for']
      c['out_Card__carded_for']['kyck_id'] == @club_id
    end
  end

  def wrap_cards
    c = @row['cards']
    return Array.wrap(c) if c.is_a?(Hash)
    return c.to_a if c.respond_to?(:to_a)
    Array.wrap(c)
  end

  def card_or_player_value_for(attr)
    if first_card && first_card[attr]
      first_card[attr]
    else
      @row[attr]
    end
  end
end

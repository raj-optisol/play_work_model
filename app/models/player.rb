class Player
  include Edr::Model
  include BaseRelationship::Model
  fields  :position, :jersey_number, :birthdate

  def_delegators :_data, :user=, :playable=

  def age
    now = Time.now.utc.to_date
    now.year - birthdate.year - (birthdate.to_date.change(:year => now.year) > now ? 1 : 0)
  end

  def user
    wrap _data.user
  end

  def playable
    wrap _data.playable
  end

  def valid?
    res = super
    if user
      unless user.valid?
        user.errors.each {|e, v| errors.add(e, v) }
        res = false
      end
    else
      errors.add(:user, "User is required")
      return false
    end

    unless birthdate_is_valid?
      errors.add :birthdate, "Birthdate is invalid"
      res = false
    end
    res
  end

  def birthdate_is_valid?
    user.birthdate &&
      (user.birthdate.strftime('%m/%d/%Y') =~ /\d{2}\/\d{2}\/\d{4}/)
  end
end

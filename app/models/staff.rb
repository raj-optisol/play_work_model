class Staff
  include Edr::Model
  include BaseRelationship::Model
  include Empowerable::Check

  fields :title, :permission_sets, :role

  def claimed?
    return false if user.nil?
    user.claimed?
  end

  def user
    wrap _data.user
  end

  def staffed_item
    wrap _data.staffed_item
  end

  def valid?
    res = super
    if user
      unless user.valid?
        user.errors.each {|e, v| errors.add(e, v) unless errors.include?(e) }
        res = false
      end
      return res
    end
    errors.add(:user, "User is required")
    false
  end

end

module Staffable

  module Model

    def get_staff()
      wrap _data.get_staff()
    end

    def get_staff_for_user(user)
      st = _data.get_staff_for_user(user)
      wrap st
    end

    def get_staff_by_id(staff_id)
      wrap _data.get_staff_by_id(staff_id)
    end

    def add_staff(user, attrs={})
      wrap _data.add_staff(user, attrs)
    end
  end

  module Data
    def add_staff(user, attrs={})
      rel = get_staff_for_user(user)
      return rel if rel
      st = user._data.staff_for.create_relationship_to(self, attrs)
      st
    end

    def get_staff()
      staff_rels.map {|r| r.wrapper}
    end

    def remove_staff(user)
      rel = get_staff_for_user(user)
      rel.destroy if rel
    end

    def get_staff_for_user(user)
      return unless user.persisted? && self.persisted?
      user._data.staff_for_rels.to_other(self).first
    end

    def get_staff_by_id(staff_id)
      get_staff.select {|s| s.kyck_id == staff_id}.first
    end

  end

end

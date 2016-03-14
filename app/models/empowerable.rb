module Empowerable

  module Data
    def permission_sets
      read_attribute(:permission_sets) || []
    end

  end

  module Check
    def has_permission?(permission)
      self.permission_sets.include?(permission)
    end

    def has_any_permission?(*permissions)
      !(self.permission_sets & permissions).empty?
    end
  end

end

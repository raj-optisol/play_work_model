module RoleRepository

  extend Edr::AR::Repository
  set_model_class Role

  def self.find_by_name(name)
    where(name: name) 
  end

  def self.find_by_kind(kind)
    where(kind: kind)
  end
end

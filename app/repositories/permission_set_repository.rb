module PermissionSetRepository
  extend Edr::AR::Repository
  set_model_class PermissionSet

  def self.find_by_name(name)
    where(name: name) 
  end
end

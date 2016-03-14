class PermissionObject

  attr_accessor :obj, :permissions
  
  def initialize(user, obje=nil, permissions=[])
    @user = user
    @permissions = permissions
    @obj = obje
  end
  
  def has_permission?(perm)
    return true if @user.kind == 'admin'
    @permissions.include?(perm) 
    
  end
  
  def obj
    @obj ||= nil
  end

end

module SanctioningRequestHelper
  def current_user_can_approve?(sr) 
    return false unless current_user
    current_user.can_manage?(
      sr.target,
      [PermissionSet::MANAGE_REQUEST])
  end
end

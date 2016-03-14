# encoding: UTF-8
class State
  include Edr::Model
  include BaseModel::Model
  include Staffable::Model

  wrap_associations :staff, :reps, :sanctioning_body

  def staff_roles
    %w(Admin Representative)
  end

  def get_admin
    get_staff.select { |s| s.title[/admin/i] }.first
  end
end

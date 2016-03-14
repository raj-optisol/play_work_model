class RoleData < ActiveRecord::Base
  self.table_name = 'roles'

  attr_accessible :id, :name, :permission_sets, :kind

end

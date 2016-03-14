class PermissionSetData < ActiveRecord::Base
  self.table_name = 'permission_sets'

  attr_accessible :id, :name, :description, :kind


end

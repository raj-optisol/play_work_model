class UserSettings
  include BaseModel::Model
  include Edr::Model
  
  fields :id, :user_id, :settings
  
  # wrap_associations :user
  
  def to_param
    id
  end
  

end

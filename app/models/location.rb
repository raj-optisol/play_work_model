class Location 
  include Edr::Model
  include BaseModel::Model

  wrap_associations :happenings
end

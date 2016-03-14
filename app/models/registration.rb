class Registration
  include Edr::Model
  include BaseModel::Model

  wrap_associations :participants, :volunteers
end

class Event
  include Edr::Model
  include BaseModel::Model
  include Locatable::Model

  # def_delegators :_data, :add_roster, :remove_roster  

  wrap_associations :schedule, :rule, :locations

  # def create_division(attrs)
  #   wrap association(:divisions).create(attrs)
  # end
  

end

class Rule
  include Edr::Model
  include BaseModel::Model

  # def_delegators :_data, :add_roster, :remove_roster  

  wrap_associations :schedule, :events

  # def create_division(attrs)
  #   wrap association(:divisions).create(attrs)
  # end

end

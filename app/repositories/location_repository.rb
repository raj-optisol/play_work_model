module LocationRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class Location

  def self.find_by_name(name)
    find_by_attrs(conditions:{name:name})
  end


end

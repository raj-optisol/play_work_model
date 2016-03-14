module StateRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class State



end

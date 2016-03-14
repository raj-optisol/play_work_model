require_relative 'condition_builder'

module SanctioningRequestProductRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class SanctioningRequestProduct
  

end

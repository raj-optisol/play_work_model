module AccountTransactionRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class AccountTransaction


end

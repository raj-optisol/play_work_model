class PaymentAccount
  include Edr::Model
  include BaseModel::Model

  fields :id, :updated_at, :obj_id, :obj_type, :balance

  wrap_associations :account_transactions
end

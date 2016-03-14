class AccountTransaction
  include Edr::Model

  fields :id, :user_id, :amount, :refunded_amount, :status, :kind, :transaction_type, :reason, :last4, :order_id, :transaction_id, :payment_account_id, :created_at
  wrap_associations :payment_account
  wrap_associations :order

  # def add_order_item(attrs)
  #   item = wrap association(:order_items).new(attrs)   
  # 
  # end
end

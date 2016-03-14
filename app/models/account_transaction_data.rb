class AccountTransactionData < ActiveRecord::Base
  include Empowerable
  self.table_name = 'account_transactions'
  self.primary_key = "id"

  attr_accessible :user_id, :amount, :status, :kind, :transaction_type, :reason, :last4, :order_id, :transaction_id, :payment_account_id, :created_at
  attr_accessible :refunded_amount, :default => 0
  belongs_to :payment_account
  belongs_to :order, class_name: "OrderData"

end

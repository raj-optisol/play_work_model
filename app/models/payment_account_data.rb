class PaymentAccountData < ActiveRecord::Base
  include ActiveUUID::UUID
  self.table_name = 'payment_accounts'
  # self.primary_key = "id"

  attr_accessible :id, :updated_at, :obj_id, :obj_type, :balance
  has_many :account_transactions, class_name: "AccountTransactionData", foreign_key: "payment_account_id"


end

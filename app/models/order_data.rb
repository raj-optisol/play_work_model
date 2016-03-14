class OrderData  < ActiveRecord::Base
  self.table_name = 'orders'
  # self.primary_key = "id"
  # include Empowerable

  # has_one :user
  #
  after_initialize :init

  attr_accessible :id, :initiator_id, :payer_id, :payer_type, :payee_id, :payee_type, :state, :created_at, :assigned_kyck_id, :assigned_name, :payer_name
  attr_accessible :kind, type: :symbol
  attr_accessible :status, type: :symbol, default: :new
  attr_accessible :amount, type: :decimal, default: 0
  attr_accessible :payment_status

  symbolize :status, in: [:new, :pending_payment, :in_progress, :submitted, :completed, :refunded, :voided, :requestor_response_required, :requestor_response_received]
  symbolize :kind, in: [:adjustment, :card_request, :sanctioning_request, :invoice, :deposit, :credit], default: :card_request
  symbolize :payment_status, in: [:not_sent, :authorized, :settled, :completed, :refunded, :voided]

  has_many :order_items, class_name: "OrderItemData", foreign_key: "order_id"
  has_many :transactions, class_name: "AccountTransactionData", foreign_key: 'order_id'

  def initiator
    repo = UserRepository
    repo.find(kyck_id: self.initiator_id.to_s)
  end

  def payer
    return unless self.payer_type
    repo = Object.const_get([self.payer_type, 'Repository' ].join)
    repo.find(kyck_id: payer_id.to_s) if repo
  end

  def payee
    return unless self.payee_type
    repo = Object.const_get([self.payee_type, 'Repository' ].join)
    repo.find(kyck_id: payee_id.to_s) if repo
  end

  private
  def init
    self.payment_status  ||= :not_sent
  end
end

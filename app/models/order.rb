class Order
  include Edr::Model
  #include BaseModel::Model
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def_delegator :_data, :initiator
  def_delegator :_data, :payer
  def_delegator :_data, :payee
  def_delegator :_data, :pending_item_count
  def_delegator :_data, :order_item_count

  fields :id, :initiator_id, :payer_id, :payer_type, :payee_id, :payment_status,
    :payee_type, :kind, :status, :amount, :state, :submitted_on, :created_at, :updated_at,
    :assigned_kyck_id, :assigned_name

  # fields :id, :user_id, :amount, :kind, :status, :organization_id
  wrap_associations :order_items, :transactions


  def add_order_item(attrs)
    item = wrap association(:order_items).create(attrs)
  end

  def get_order_items (attrs={}, options={})
    repository.get_order_items self, attrs, options
  end

  def get_sum (attrs={}, options={})
    return amount if [:deposit].include?(kind)
    repository.get_sum self, attrs, options
  end

  def refunded_transactions
    transactions.select{|s| s.status == "refunded"}
  end

  def non_refunded_transactions
    transactions.select{|s| s.status != "refunded"}
  end

  def update_order_items(update_attrs, attrs={})
    repository.update_order_items self, update_attrs, attrs
  end

  def persisted?
    _data.persisted?
  end

  def new?
    status == :new
  end

  def paid?
    status == :paid
  end

  def completed?
    status == :completed
  end


end

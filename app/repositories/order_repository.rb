module OrderRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class Order

  def self.latest_order_for_card(card)
    order = OrderData.joins(:order_items).where(
      order_items: { item_id: card.kyck_id, item_type: 'Card' }
    ).order(submitted_on: :desc).limit(1)

    return wrap order if order
  end

  def self.orders_for_card(card, conditions = {}, latests = false, limit = nil)
    orders = OrderData.includes(:order_items).where(
      "order_items.item_id = '#{card.kyck_id}'"
    ).order("orders.submitted_on DESC")

    orders = orders.limit(limit) if limit
    orders.map! { |order| wrap order }
    return orders.first if latests

    orders
  end

  def self.orders_for_card_join(card)
    orders = OrderData.select('orders.*').joins(:order_items).where(order_items: { item_id: card.kyck_id, item_type: 'Card' })
    orders.map { |order| wrap order }
  end

  def self.wrapper(order)
    wrap order
  end

  def self.get_order_items obj, attrs={}, opts={}
    opts = {order: "id desc", limit: 25, offset: 0}.merge(opts)
    attrs = {:order_id=>obj.id}.merge(attrs)
    OrderItemRepository.find_by_attrs(attrs, opts)
  end

  def self.get_sum obj, attrs={}, opts={}
    attrs = {:order_id=>obj.id}.merge(attrs)
    OrderItemRepository.get_sum(attrs, opts)
  end

  def self.update_order_items obj, update_attrs={}, attrs={}
    attrs = {:order_id=>obj.id}.merge(attrs)
    OrderItemRepository.update_order_items(attrs, update_attrs)
  end

  def self.all_new_with_user_card(user)
    OrderData.select('orders.*').joins(:order_items).
      where('orders.status = ?', :new).
      where('order_items.product_type = ?', 'CardProduct').
      where('order_items.product_for_obj_type = ?', 'User').
      where('order_items.product_for_obj_id = ?', user.kyck_id).
      group('orders.id, order_items.id').
      includes(:order_items).map { |o| wrap o }
  end

  def self.group(order)

    case order.kind
    when :sanctioning_request
      OrderItemData.select("name, product_type, product_id, count(order_items.id) as quantity, sum(order_items.amount) as line_total, sanctioning_request_products.*").joins("inner join sanctioning_request_products on product_id = sanctioning_request_products.id").where("order_id=?", order.id).group("product_type, product_id, sanctioning_request_products.id")

    when :card_request
      OrderItemData.select("name, product_type, product_id, count(order_items.id) as quantity, sum(order_items.amount) as line_total, card_products.*").joins("inner join card_products on product_id = card_products.id").where("order_id=?", order.id).group("product_type, product_id, card_products.id")
    else

    end
  end

  def self.assigned_filter_values
    OrderData.select("DISTINCT(assigned_kyck_id), assigned_name").where("assigned_kyck_id IS NOT NULL").order("assigned_name")
  end

  module OrderItemRepository
    extend Edr::AR::Repository
    extend CommonFinders::ActiveRecord
    set_model_class OrderItem

    def self.get_sum(attrs, opts)
      conditions = ConditionBuilder::SQL.build(attrs)
      data_class.klass.where(conditions).sum('amount')
    end

    def self.update_order_items(attrs, update_attrs)
      conditions = ConditionBuilder::SQL.build(attrs)
      data_class.klass.where(conditions).update_all(update_attrs)
    end

    def self.get_order_items_for_order(order, conditions)
      conditions[:order_id] = order.id
      conditions = ConditionBuilder::SQL.build(conditions)
      data_class.klass.where(conditions).map {|oi| wrap oi}
    end

    def self.get_order_items_for_user(conditions)
      conditions = ConditionBuilder::SQL.build(conditions)
      items = OrderItemData.where(conditions)
      items.map { |i| wrap i }
    end

    def self.order_items_for_card(card, conditions = {})
      items = OrderItemData.where(
        "item_id = '#{card.kyck_id}' AND item_type = 'Card'"
      )

      items.map { |i| wrap i }
    end
  end


end

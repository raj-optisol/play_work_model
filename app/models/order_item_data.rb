# encoding: UTF-8
class OrderItemData < ActiveRecord::Base
  self.table_name = 'order_items'
  belongs_to :order, class_name: 'OrderData', foreign_key: 'order_id'
  counter_culture(:order,
                  column_name: 'order_item_count')
  counter_culture(:order,
                  column_name: proc { |model| model.new? ? 'pending_item_count' : nil })

  attr_accessible(
    :id,
    :status,
    :product_for_obj_id,
    :product_for_obj_type,
    :order_id,
    :amount,
    :product_id,
    :product_type,
    :description,
    :competition_id,
    :item_type,
    :item_id
  )

  def new?
    status.to_s == 'new'
  end
end

class SanctioningRequestProductData < ActiveRecord::Base
  include Symbolize::ActiveRecord

  self.table_name = 'sanctioning_request_products'

  attr_accessible :sanctioning_body_id, :kind, :amount, :active

  symbolize :kind, in: [:club, :academy, :league, :tournament]

  # validates :kind, uniqueness: true, presence: true
  validates_uniqueness_of :kind, :scope => [:sanctioning_body_id]
  validates :kind, presence:true

end

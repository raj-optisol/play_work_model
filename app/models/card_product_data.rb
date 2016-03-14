class CardProductData< ActiveRecord::Base
  self.table_name = 'card_products'
  acts_as_paranoid

  after_initialize :init

  attr_accessible :sanctioning_body_id, :organization_id, :age, :card_type, :amount, :name, :deleted_at

  symbolize :card_type, in: [:player, :staff]

  validates_uniqueness_of :card_type, :scope => [:age, :sanctioning_body_id, :organization_id, :deleted_at]
  validates :name, presence: true

  def init
    self.card_type ||= :player
  end

end

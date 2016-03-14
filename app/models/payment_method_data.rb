class PaymentMethodData < ActiveRecord::Base
  self.table_name = 'payment_methods'

  attr_accessible :id, :updated_at, :user_id, :description, :name, :address, :city, :state, :zipcode, :last4, :customer_id, :card_token, :expiration_month, :expiration_year, :kind

  symbolize :kind, in: [:amex, :visa, :mc, :disc]

  belongs_to :user, class_name: "UserData"

end

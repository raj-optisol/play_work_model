class PaymentMethod
  include Edr::Model

  fields  :id, :updated_at, :user_id, :description, :name, :address, :city, :state, :zipcode, :last4, :customer_id, :card_token, :expiration_month, :expiration_year, :kind

end

module PaymentMethodRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class PaymentMethod

  # def self.find_by_email(email)
  #   where(email: email)
  # end
  #
  # def self.find_by_kyck_id(kyck_id)
  #   where(kyck_id: kyck_id)
  # end

  def self.get_payment_methods(user)
    where(user_id: user.kyck_id)
  end

end

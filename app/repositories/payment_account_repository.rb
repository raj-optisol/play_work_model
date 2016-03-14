module PaymentAccountRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord
  set_model_class PaymentAccount

  # def self.find_by_email(email)
  #   where(email: email)
  # end
  #
  # def self.find_by_kyck_id(kyck_id)
  #   where(kyck_id: kyck_id)
  # end

  def self.for_kyck_ids(kyck_ids)
    res = data_class.klass.where("obj_id IN (?)", kyck_ids)
    res.to_a.map { |pa| wrap pa }
  end
end

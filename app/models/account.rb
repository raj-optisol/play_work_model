class Account < ActiveRecord::Base
  attr_accessible :email, :kyck_id, :kyck_token, :kind
  devise :omniauthable, :trackable

  def self.find_for_omniauth_authentication(omniauth)
    kyck_id = omniauth["uid"]
    email = omniauth["info"]["email"].downcase
    logger.info "email=#{email}"
    where(kyck_id: kyck_id).first || where(email: email).first
  end

  def self.find_or_create_for_cookie(cookie)
    id = cookie['account']['kyck_id']
    email = cookie['account']['email']

    a = where(kyck_id: id).first || Account.where(email: email).first
    return a if a

    kind = cookie['account']['kind']
    first_name = cookie['account']['first_name']
    last_name = cookie['account']['last_name']

    a = Account.create!(
      email: email.downcase,
      kyck_id: id,
      kind: kind
    )
  end

  def claimed?
    self.sign_in_count > 0
  end
end

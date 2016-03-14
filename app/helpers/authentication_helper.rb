# encoding: UTF-8
module AuthenticationHelper
  def set_user_auth_token
    RequestStore.store[:kyck_token] = current_account.try(:kyck_token)
  end

  def authenticate_with_cookie
    return if current_user
    return if env['omniauth.auth']
    sd = decrypt_cookie(auth_cookie)
    return unless sd && sd['account']
    puts sd
    account = find_account_for_cookie(sd)
    return unless account
    redirect_to account_omniauth_authorize_path(:kyck)
  end

  def current_user
    return Null::User.new unless current_account
    (@current_user ||= UserRepository.find_for_account(current_account))
    @current_user.extend(UserRepresenter) if @current_user
  end

  def authenticate_with_permissions!(_,
                                     permission,
                                     admin_required = false,
                                     obj_to_test_permissions = nil)
    authenticate_account!
    message = I18n.t('errors.messages.required_permission') ||
      'Required Permission'
    has_permission = permission_for_obj?(obj_to_test_permissions,
                                         permission,
                                         admin_required)

    respond_to do |format|
      format.html { redirect_to root_url, alert: message unless has_permission }
      format.json do
        render(json: { error: message }, status: 401) unless has_permission
      end
    end
    has_permission
  end

  def permission_for_obj?(obj, perm, admin_required)
    if obj && !admin_required
      current_user.can_manage?(
        obj,
        [perm])
    else
      current_user.admin?
    end
  end

  def authorize_kyck_user
    fail KyckRegistrar::PermissionsError unless valid_kyck_user?
  end

  def authorize_uscs_user
    fail KyckRegistrar::PermissionsError unless valid_uscs_user?
  end

  def authorize_kyck_uscs_user
    is_user_valid = valid_kyck_user? || valid_uscs_user?
    fail KyckRegistrar::PermissionsError unless is_user_valid
  end

  def valid_kyck_user?
    return false if current_user.blank?
    current_user.email =~ /^.*@kyck.com$/
  end

  def valid_uscs_user?
    return false if current_user.blank?
    current_user.email =~ /^.*@usclubsoccer.org$/
  end

  def find_account_for_cookie(cookie)
    account = Account.find_or_create_for_cookie(cookie)
    return unless account
    ensure_user(account, cookie)
    account
  end

  def ensure_user(account, cookie)
    UserRepository.find_or_create_for_account(
      account,
      first_name: cookie['account']['first_name'],
      last_name: cookie['account']['last_name'],
      email: account.email.downcase,
      kyck_id: account.kyck_id.to_s
    )
  end

  def decrypt_cookie(cookie)
    return unless cookie
    kg = ActiveSupport::KeyGenerator.new(
      Settings.kyck_auth.secret_base_key,
      iterations: 1000)
    sec = kg.generate_key(
      Rails.application.config.action_dispatch.encrypted_cookie_salt)
    salt = kg.generate_key(
      Rails.application.config.action_dispatch.encrypted_signed_cookie_salt)
    encryptor = ActiveSupport::MessageEncryptor.new(sec, sign_secret: salt)
    encryptor.decrypt_and_verify(cookie)
  end

  def auth_cookie
    cookies['_oauth_provider_session'] and URI.unescape(cookies['_oauth_provider_session'])
  end
end

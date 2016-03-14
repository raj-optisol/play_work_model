class User
  include Edr::Model
  include BaseModel::Model
  include Locatable::Model
  include Documentable::Model

  wrap_associations :staff_for, :admin_for, :plays_for, :requests, :accounts, :owners, :locations, :cards, :documents, :rep_for

  def_delegators :_data, :has_organization?
  def_delegators :_data, :can_manage?
  def_delegators :_data, :has_permission?
  def_delegators :_data, :has_permission_for
  def_delegators :_data, :permission_sets_for_obj
  def_delegators :_data, :can_manage_user?
  def_delegators :_data, :get_players
  def_delegators :_data, :avatar?
  def_delegators :_data, :avatar_version

  def admin?
    kind.to_s == 'admin'
  end

  def full_name
   names = [first_name]
   names << middle_name unless middle_name.blank?
   names << last_name
   names.join(' ')
  end

  def address
    return '' unless locations && locations.first

    location = locations.first
    full_address = [location.address1]
    full_address << location.address2
    full_address << location.city
    full_address << location.state
    full_address << location.zipcode
    full_address << location.country

    full_address.join(' ')
  end

  alias :name :full_name

  def age
    return -1 unless birthdate
    age = Date.today.year - birthdate.year
    age -= 1 if Date.today < birthdate + age.years #for days before birthday
    age
  end

  def get_organizations
    wrap _data.get_organizations()
  end

  def get_staff_relationships()
    wrap _data.get_staff_relationships
  end

  def add_player(attrs)
    wrap association(:players).new(attrs)
  end

  def claimed?
    self.claimed == true
  end

  def save(val=true)
    _data.save(val)
  end

  def add_user(user, attrs={})
    UserRepository.persist user unless user.persisted? && self.persisted?

    obj = user._data.owners_rels.to_other(self._data).first
    return user if obj
    self._data.accounts.create_relationship_to(user._data, attrs)
    user
  end

  def create_document(attrs)
    wrap association(:documents).create(attrs)
  end

  def confirmed_accounts
    _data.accounts_rels.find_all{|a| a[:confirmed] == true}.collect{|n| wrap n.start_vertex}
  end

  def authentication_account
    return unless persisted?
    (Account.where(kyck_id: kyck_id) || Account.where(email: email)).first
  end
end

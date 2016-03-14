class SanctioningBody
  include Edr::Model
  include BaseModel::Model
  include Staffable::Model
  include Locatable::Model

  fields  :name, :url

  wrap_associations :sanctions, :sanctioning_requests, :staff, :locations, :cards, :merchant_account, :states

  def_delegators :_data, :remove_staff
  def_delegators :_data, :avatar?


  def sanction(thing, attrs={})
    wrap _data.add_sanction(thing, attrs)
  end

  def create_sanctioning_request(issuer, org_to_sanction, payload={})
    sb = SanctioningRequest.build(status: :pending, issuer: issuer._data, on_behalf_of: org_to_sanction._data, payload: payload)
    association(:sanctioning_requests)<< sb._data
    sb
  end

  def viewable_by?(user, rels=[])
    repository.viewable_by?(user, self, rels)
  end

  def sanctions?(org)
    org.sanctioning_bodies.map(&:kyck_id).include?(self.kyck_id)
  end

  # TODO: Move this to an action
  def card_user_for_organization(user, organization, card_attrs={})
    card = Card.build
    card.kind = card_attrs.fetch(:kind, :player)
    card.status = card_attrs.fetch(:status, :requested)
    card.expires_on = card_attrs.fetch(:expires_on, 1.year.from_now.to_i)
    card.sanctioning_body = self._data
    card.carded_user = user._data
    card.carded_for = organization._data
    card.first_name = user.first_name
    card.last_name = user.last_name
    card.birthdate = user.birthdate
    CardRepository.persist(card)
  end

  def new_card_requests
    OrderRepository.find_by_attrs({:status => 'submitted', :payee_id => self.kyck_id, :kind => 'card_request'})
  end

  def new_card_requests_count
    OrderData.where(status: "submitted", payee_id: self.kyck_id, kind: 'card_request').count
  end

  def available_permission_sets
    PermissionSet.for_uscs()
  end

  def get_state(state)
    states.select{|s| s.abbr[/#{state}$/i]} .first
  end


end

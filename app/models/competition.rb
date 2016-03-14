# encoding: UTF-8
class Competition
  include Edr::Model
  include BaseModel::Model
  include Staffable::Model
  include Locatable::Model

  def_delegators :_data, :remove_staff
  def_delegators :_data, :viewable_by?
  def_delegators :_data, :avatar?
  def_delegators :_data, :avatar_version

  wrap_associations(
    :staff,
    :divisions,
    :sanctioning_requests,
    :locations,
    :sb_region,
    :sanctioning_bodies,
    :entries,
    :sb_rep,
    #TODO: Remove this once data migration is run
    :organization,
    :cards
  )

  def create_division(attrs)
    wrap association(:divisions).create(attrs)
  end

  def get_division_by_kyck_id(division_id)
    divisions.select { |division|  division.kyck_id == division_id }.first
  end

  def avatar_url
    if self
      return "http://res.cloudinary.com/kyck-com/image/upload/v1423245360/default_organization_avatar_i68wap" unless self.avatar
      Cloudinary::Utils.cloudinary_url(self.avatar, {secure: true, format: :png})
    end
  end

  def sanctioned?
    sanctioning_bodies.any?
  end

  def staff_roles
    %w(Registrar Director Manager Other)
  end

  def available_permission_sets
    return PermissionSet.for_competition unless can_process_cards_for_sb?
    PermissionSet.for_competition_with_cards
  end

  def can_process_cards_for_sb?(sb = nil)
    sb ||= SanctioningBodyRepository.all.first
    sanction = _data.sanctioning_bodies_rels.to_other(sb._data).first
    return false  unless sanction
    sanction.can_process_cards
  end
end

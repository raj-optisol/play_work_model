require 'validation'
class SanctioningBodyData < BaseModel::Data
  include Staffable::Data
  include Locatable::Data
  include Avatarable::Data
  include Validation
  has_avatar default: 'default_organization_avatar_i68wap'

  property :name, index: :exact
  property :url, type: String
  property :phone_number
  property :fax_number
  property :email
  property :merchant_account_id


  #attr_validator :name, String

  has_one(:merchant_account).to(MerchantAccountData)

  has_n(:sanctions).relationship(SanctionData)
  has_n(:sanctioning_requests).from(:target)
  has_n(:staff).from(:staff_for)
  has_n(:locations).to(LocationData)
  has_n(:cards).from(CardData, :sanctioning_body)
  has_n(:states).to(StateData)

  def self.where(attrs)
    query = DB.query.labels(odb_class_name)
    query.tap do |q|
      attrs.each_pair do |key, val|
        q.has(key.to_s, val)
      end
    end
  end

  def add_sanction(thing, attrs={})
    rel = get_sanction_for_item(thing)
    return rel if rel

    self.sanctions_rels.create_relationship_to(thing._data, attrs)
  end

  def get_sanction_for_item(item)
    return unless item.persisted? && item.persisted?
    item._data.sanctioning_bodies_rels.to_other(self).first
  end

  def can_user_manage?(user, permissions=[], all_perms=true)

    retval = false
    begin
        permstr = "'#{permissions.join("', '")}'"
        if all_perms
          checkpermsstr = "and intersect(permission_sets, set(#{permstr})).size() = #{permissions.count} "
        else
          checkpermsstr = "and permission_sets IN [#{permstr}]"
        end
        sql = "select from (traverse in_staff_for from #{self.id}) where out.@rid = #{user.id} #{checkpermsstr}"
        cmd = OrientDB::SQLCommand.new(sql)
        res = Oriented.graph.command(cmd).execute
        r = res.to_a
        retval = !r.empty?
        retval
    rescue => e
      puts e.inspect
      false
    end
    retval
  end

end

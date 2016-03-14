require_relative 'empowerable'
require_relative 'locatable'
require_relative 'avatarable'
require_relative 'documentable'
require_relative 'card_data'
require 'symbolize'

class UserData < BaseModel::Data
  include Empowerable::Data
  include Symbolize::ActiveRecord
  include Locatable::Data
  include Avatarable::Data
  include Documentable::Data

  has_avatar default: 'user_avatar_syy1gy'

  property :first_name
  property :middle_name
  property :last_name
  property :migrated_id
  property :kind, type: :symbol, default: :user
  property :email
  property :phone_number
  property :phone_number_validated, :type => :boolean, default: false
  property :mobile_validation_code, index: :exact, unique: true
  property :permission_sets
  property :birthdate, :type => Date
  property :gender, type: :symbol, default: :male
  property :claimed, default: false
  property :suffix

  property :card_expiration, type: Fixnum  # used for migration
  property :background_check


  has_n(:staff_for).relationship(StaffData)
  has_n(:plays_for).relationship(PlayerData)
  has_n(:registered_for)
  has_n(:volunteered_for)
  has_n(:admin_for)
  has_n(:locations).to(LocationData)
  has_n(:requests).from(:issuer)
  has_n(:cards).from(CardData, :carded_user)
  has_n(:documents).from(DocumentData, :owner)

  has_n(:owners).to(UserData)
  has_n(:accounts).from(UserData, :owners)

  has_n(:rep_for)

  symbolize :kind, in: [:user, :admin]
  symbolize :gender, in: [:male, :female]

  validates :kyck_id, presence: true #, uniqueness: true
  validates :first_name, presence: true


  def has_organization?
    !!(self._rels(:outgoing, :staff_for).count > 0)
  end

  def get_staff_relationships
    self.rels(:outgoing, :staff_for)
  end

  def get_organizations
    staff_for{|m| m[:_classname]=='OrganizationData'}.to_a
  end

  def can_manage?(objs, permissions=[], all_perms=true)
    return true if self.kind.to_s == 'admin'
    objs = objs.is_a?(Array) ? objs : [objs]
    retval = false

    begin
      objs.each do |obj|
        obj = obj._data if obj.respond_to?(:_data)

        if obj.respond_to?(:can_user_manage?)
          retval = obj.can_user_manage?(self, permissions, all_perms)
          break if retval
          next
        end

        @gp = KyckPipeline.new(Oriented.graph)
        @gp1 = KyckPipeline.new(Oriented.graph)
        @gp2 = KyckPipeline.new(Oriented.graph)

        pf = KyckPipeFunction.new
        pf.send(:define_singleton_method, :compute) do |arg| arg.loops < 5 end
        pf2 = KyckPipeFunction.new
        pf2.send(:define_singleton_method, :compute) do |arg| true; end
        self.__java_obj.load
        @gp.start(self.__java_obj).outE("staff_for").filter{|it|
          if(it["permission_sets"])
            if(all_perms)
              it["permission_sets"].containsAll(permissions)
            else
              perms = it["permission_sets"].to_a
              hasperm = false
              permissions.each{|p|
                 if perms.include?(p)
                    hasperm = true
                    break
                  end
              }
              hasperm

            end
          else
            false
          end }.as("staff").inV.filter{|it| it["@class"] != 'SanctioningBody'}
        @gp.or(@gp1.filter{|it| it.id.toString() == obj.id.to_s}, @gp2._().outE.filter{|it| it.label != SanctioningBodyData.relationship_label_for(:sanctions)}.inV.loop(3, pf, pf2).filter{|it| it.id.toString() == obj.id.to_s}).back("staff")
        r = @gp.to_a

        retval = !r.empty?
        break if retval
      end
      retval
    rescue Exception => e
      puts e.inspect
      Rails.logger.info("EXCEPTION: #{e.inspect}")
      false
    end
  end

  def can_manage_user?(user, permissions=[])
    return true if self.kind.to_s == 'admin'
    return true if self.kyck_id == user.kyck_id
    self.accounts.each{|u|
      return true if u.kyck_id == user.kyck_id
    }
    #begin
    if !user.claimed?
      user.plays_for.each do |obj|
        return true if self.can_manage?(obj, [PermissionSet::MANAGE_PLAYER])
      end
    end

    user.staff_for.each do |obj|
      return true if self.can_manage?(obj, [PermissionSet::MANAGE_STAFF])
    end

    false
  end

  def get_players(filters)
    if filters[:conditions]
      ConditionBuilder::OrientGraph.build(self.plays_for_rels.as_query, filters[:conditions]).edges.map {|e| e.wrapper}
    else
      self.plays_for_rels
    end
  end

  def has_permission?(obj, permissions=[], all_perms=true)
    return true if self.kind.to_s == 'admin'
    r = self.has_permission_for(obj, permissions, all_perms, false)
    return !r.empty?
  end

  def has_permission_for(obj, permissions=[], all_perms=true, wrapit=true)
    return [ ] if self.kind.to_s == 'admin'
    obj = obj._data if obj.respond_to?(:_data)

    bothrel = ['Organization__teams', 'Team__rosters']

    permobjs = []
    begin
        permstr = "'#{permissions.join("', '")}'"
        if all_perms
          checkpermsstr = "and intersect(permission_sets, set(#{permstr})).size() = #{permissions.count} "
        else
          checkpermsstr = "and permission_sets IN [#{permstr}]"
        end
        sql = "select from (traverse in_staff_for from (traverse both('"+(bothrel.join("'),both('"))+"') from #{obj.id} while $depth < 3)) where out.@rid = #{self.id} #{checkpermsstr}) where @class = 'staff_for'"
        # puts sql
        cmd = OrientDB::SQLCommand.new(sql)
       res = Oriented.graph.command(cmd).execute

      if wrapit
        permobjs = res.collect{|c| c.wrapper.model_wrapper }
      else
        permobjs = res.to_a
      end

    rescue Exception=>e
      puts e.inspect
      Rails.logger.info("EXCEPTION: #{e.inspect}")
    end
    permobjs
  end

  def permission_sets_for_obj(obj)
    return obj.available_permission_sets() if self.kind.to_s == 'admin'
    obj = obj._data if obj.respond_to?(:_data)

    permobjs = []
    begin
      @gp = KyckPipeline.new(Oriented.graph)
      @gp1 = KyckPipeline.new(Oriented.graph)
      @gp2 = KyckPipeline.new(Oriented.graph)
      @gp3 = KyckPipeline.new(Oriented.graph)

      while_pf = KyckPipeFunction.new
      while_pf.send(:define_singleton_method, :compute) do |arg| arg.loops < 5 end
      emit_pf = KyckPipeFunction.new
      emit_pf.send(:define_singleton_method, :compute) do |arg| true; end
      self.__java_obj.load
      @gp.start(self.__java_obj).outE("staff_for").as("staff").inV

      @gp.or(@gp1.filter{|it| it.id.toString() == obj.id.to_s}, @gp2._().outE.filter{|it| it.label != SanctioningBodyData.relationship_label_for(:sanctions)}.inV.loop(3, while_pf, emit_pf).filter{|it| it.id.toString() == obj.id.to_s}).back("staff")
      permobjs = @gp.to_a

      permobjs = permobjs.collect{|c| c.wrapper.permission_sets.to_a }.flatten

    rescue Exception=>e
      puts e.inspect
      Rails.logger.info("EXCEPTION: #{e.inspect}")
    end
    permobjs
  end
end

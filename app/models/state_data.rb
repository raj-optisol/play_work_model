class StateData < BaseModel::Data
  include Staffable::Data

  property :name, :abbr

  has_n(:reps).from(:rep_for)
  has_n(:staff).from(:staff_for)
  has_one(:sanctioning_body).from(SanctioningBodyData, :states)

  def can_user_manage?(user, permissions=[], all_perms=true)

    retval = false
    begin
      permstr = "'#{permissions.join("', '")}'"
      if all_perms
        checkpermsstr = "and intersect(permission_sets, set(#{permstr})).size() = #{permissions.count} "
      else
        checkpermsstr = "and permission_sets IN [#{permstr}]"
      end
      sql = "select * from (traverse in_SanctioningBody__states from #{self.id}) let $st = (select @rid from $current.in_staff_for where out.@rid = #{user.id} #{checkpermsstr}) where $st.size() > 0"
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

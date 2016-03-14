# encoding: UTF-8
class RosterStaffRow
  include RosterRowMethods
  def initialize(row, club_id)
    @row = row
    @club_id = club_id
  end

  def staff_id
    @row['migrated_id'] || @row['kyck_id'][0..10]
  end

  def title
    @row['staff']['title']
  end
end

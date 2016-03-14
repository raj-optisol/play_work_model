module SanctioningBodyRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class SanctioningBody

  def self.find_by_name(name)
    find_by_attrs(conditions:{name:name})
    # SanctioningBodyData.where(name: name)
  end

  def self.viewable_by?(user, sb,  rels=[])
    true
  end

  def self.get_sanctions_status(sb, opts={})
    @res = {}
    sb = sb || SanctioningBodyRepository.all.first
    gp = KyckPipeline.new(Oriented.graph)
    sql = 'select status, count(status) from ' \
      "(select expand(out('sanctions') from #{sb._data.id})"
    sql_pipeline(gp, sql).to_a.each{|r|
      prop = r.get_property("status")
      return [] if prop.blank?
      @res[prop] = r.get_property("count")
    }
    return @res
  end

  def self.sql_pipeline(gp, sql)
    gp.KV("sql", sql)
  end
end

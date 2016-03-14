# encoding: UTF-8
require 'symbolize'
class TeamData < BaseModel::Data
  include Staffable::Data
  include Symbolize::ActiveRecord
  include Avatarable::Data

  has_one(:home_organization).to(OrganizationData)
  has_n(:rosters).to(RosterData)
  has_n(:staff).from(:staff_for)

  has_one(:organization).from(OrganizationData, :teams)

  has_n(:schedules).to(ScheduleData)

  has_n(:competition_entries).from(CompetitionEntryData, :team)

  [:name, :player_count, :migrated_id].each {|prop| property prop}
  property :open, :type => :boolean, default: false

  property :born_after, :type => Date

  property :avatar, default: 'default_team_avatar_cevo3y'
  has_avatar default: 'default_team_avatar_cevo3y'

  property :gender, type: :symbol
  symbolize :gender, in: [:male, :female, :coed]

  def viewable_by?(user, rels=[])
    return true if user.admin?

    begin
      @gp = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp1 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp2 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp3 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp4 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)

      while_pf = KyckPipeFunction.new
      while_pf.send(:define_singleton_method, :compute) do |arg| arg.loops < 3 end
      emit_pf = KyckPipeFunction.new
      emit_pf.send(:define_singleton_method, :compute) do |arg| true; end

      user._data.__java_obj.load
      @gp.start(user._data.__java_obj).outE # Start with the user, get out edges
      @gp.filter{|it| rels.include?(it.label)} if rels.count > 0 # Filter if relationship labels supplied
      @gp.inV.or(
        @gp1.filter{|it| it.id.toString() == self.id.to_s}, # Is the current object self? If not, OR
        @gp2.in("Team__rosters").filter{|it| it.id.toString() == self.id.to_s}, # Check my rosters for the user
        @gp4.outE.filter{|it|  %w(Organization__teams).include?(it.label)}.inV.loop(3, while_pf, emit_pf).filter{|it| it.id.toString() == self.id.to_s}) # Loop over all outgoing for self

      r = @gp.to_a
      return !!r.first
    rescue Exception => e
      puts e.inspect
      Rails.logger.info("EXCEPTION: #{e.inspect}")
    end

    false

  end

  def get_players(filter={})
    # player_rel_label = UserData.relationship_label_for(:plays_for)
    # rosters_rel_label = TeamData.relationship_label_for(:rosters)
    #
    # pipeline = KyckPipeline.new(Oriented.graph)
    # self.__java_obj.load
    # pipeline.start(self.__java_obj)
    #
    # pipeline.out(rosters_rel_label).inE(player_rel_label).to_a.map {|p| p.wrapper}
  end

  def self.get_age_groups()
    ages = []
    (4..22).each{|a| ages.push("U#{a}") }
    ages.push("Adult")
    ages
  end
end

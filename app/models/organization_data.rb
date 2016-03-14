class OrganizationData < BaseModel::Data
  include Staffable::Data
  include Locatable::Data
  include Symbolize::ActiveRecord
  include Avatarable::Data
  include Documentable::Data
  ORG_KINDS = [:club, :academy]
  has_avatar default: 'default_organization_avatar_i68wap'

  has_n(:staff).from(:staff_for)
  has_n(:cards).from(CardData, :carded_for)
  has_n(:teams).to(TeamData)

  has_n(:locations)
  has_n(:documents).from(DocumentData, :organization)

  property :name
  property :migrated_id
  property :status, type: :symbol, default: :active
  property :email
  property :url
  property :phone_number
  property :fax_number
  property :born_after, type: Date
  property :kind, type: :symbol

  validates :kind, inclusion: { in: ORG_KINDS }, allow_nil: true

  validates :name, presence: true, unique: {repository: OrganizationRepository}

  symbolize :status, in: [:active, :inactive]

  #has_n(:orders).to(OrderData)
  has_n(:home_teams).from(TeamData, :home_organization)

  has_n(:competitions).to(CompetitionData)
  has_n(:sanctioning_requests).from(:on_behalf_of)
  has_n(:sanctioning_bodies).from(:sanctions)

  has_one(:sb_rep).from(:rep_for)

  def add_competition(competition, attrs={})
    rel = competitions_rels.to_other(competition._data)
    return rel if rel.first
    competitions.connect(competition._data, attrs)
  end

  def add_team(team, attrs={})
    rel = teams_rels.to_other(team._data)
    return rel if rel.first
    teams.connect(team._data, attrs)
  end

  def remove_team(team)
    rel = teams_rels.to_other(team._data)
    rel.first.remove if rel

    orel = team._data.organization_rel
    orel.remove if orel
  end

  def sanctioned?
    return false unless persisted?
    sanctioning_bodies_rels.select { |s| s.status == :active }.length > 0
  end

  def pending_sanction?
    return false unless persisted?
    sanctioning_requests.select { |s| s.status == (:pending || :pending_payment) }.length > 0
  end

  def viewable_by?(user, rels=[])
    return true if user.admin?
    begin
      @gp = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp1 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp2 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp3 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      @gp4 = OrientDB::Gremlin::GremlinPipeline.new(Oriented.graph)
      while_pf = KyckPipeFunction.new
      while_pf.send(:define_singleton_method, :compute) do |arg| arg.loops < 5 end
      emit_pf = KyckPipeFunction.new
      emit_pf.send(:define_singleton_method, :compute) do |arg| true; end

      @gp.start(user._data.__java_obj).outE # Start with the user, get out edges
      @gp.filter{|it| rels.include?(it.label)} if rels.count > 0 # Filter if relationship labels supplied
      @gp.inV.or(
        @gp1.filter{|it| it.id.toString() == id.to_s}, # Is the current object self? If not, OR
        @gp2.out('Organization__teams').filter { |it| it.id.toString() == id.to_s } # Is the current object self?
      )
      r = @gp.to_a
      return !!r.first
    rescue Exception => e
      Rails.logger.info("EXCEPTION: #{e.inspect}")
    end

    false
  end
end

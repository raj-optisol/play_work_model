class SanctionData < BaseRelationship::Data
  include Empowerable::Data
  include Symbolize::ActiveRecord

  property :status, default: :active
  property :can_process_cards, default: false

  symbolize :status, in: [:active, :inactive]

  def self.get_kind_values
    [['Organization', [['All', 'Organization']]], ['Competition', [['All', 'Competition']].concat(CompetitionData.get_kind_values)]]
  end

  # BAD KEVIN
  def sb
    self.start_vertex
  end

  def sanctioning_body
    self.start_vertex
  end

  def sanctioned_item
    self.end_vertex
  end

end

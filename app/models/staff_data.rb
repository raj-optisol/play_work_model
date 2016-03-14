require 'symbolize'
require_relative 'base_relationship'
require_relative 'empowerable'
class StaffData < BaseRelationship::Data
  include Empowerable::Data
  include Symbolize::ActiveRecord

  property :title,  :permission_sets
  property :role, default: :fulltime

  symbolize :role, in: [:fulltime, :parttime, :volunteer, :Admin, :Representative]

  def user
    self.start_vertex
  end

  def staffed_item
    self.end_vertex
  end

end

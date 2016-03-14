class PlayerData < BaseRelationship::Data
  property :position, :jersey_number
  property :birthdate, type: DateTime

  def user
    self.start_vertex
  end

  def playable
    self.end_vertex
  end

end

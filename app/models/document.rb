class Document
  include Edr::Model
  include BaseModel::Model

  def_delegators :_data, :last_reviewer, :remove_owner

  wrap_associations :owner, :organization, :cards

  def reviewed?
    status != :not_reviewed 
  end

  def organization=(org)
    _data.organization= org._data
    org
  end

  def owner=(user)
    _data.owner= user._data
    user
  end

end


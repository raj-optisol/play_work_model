class Note
  include Edr::Model
  include BaseModel::Model
  fields :text

  wrap_associations :author, :target

  def author=(author)
    _data.author = author._data
  end

  def target=(target)
    _data.target = target._data
  end

end

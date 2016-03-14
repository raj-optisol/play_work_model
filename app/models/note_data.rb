# encoding: UTF-8
class NoteData < BaseModel::Data
  property :text 

  has_one(:author).to(UserData)
  has_one(:target)
end

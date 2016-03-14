require 'factory_girl'

FactoryGirl.define do
  factory :note, class: NoteData do
    text {"Lorem ipsom"}
  end
end

def create_note_for_target(target, attrs={})
  note = FactoryGirl.create(:note, attrs)
  n = NoteRepository.find(note.id)
  target.add_note(n)
  target._data.save!
end



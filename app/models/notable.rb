module Notable
  module Model
    def get_note()
      wrap _data.get_note()
    end

    def add_note(note)
      wrap _data.add_note(note)  
    end

    def create_note(note_attrs)  
      wrap _data.create_note(note_attrs)
    end

  end

  module Data
    def create_note(note_attrs)
      note_attrs[:author] = note_attrs[:author]._data if note_attrs.has_key?(:author)
      notes.create(note_attrs)
    end

    def add_note(note)
      self.notes << note._data
      note._data
    end

    def get_notes()
      self.notes.map {|r| r.wrapper}
    end

    def remove_note(note)
      rel = get_note_by_id(note.kyck_id)
      rel.destroy if rel
    end

    def get_note_by_id(note_id)
      get_notes.select {|l| l.kyck_id == note_id}.first
    end
  end
end

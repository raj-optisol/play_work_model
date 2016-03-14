module Documentable
  module Model
    def get_documents()
      wrap _data.get_documents()
    end

    def add_document(document)
      wrap _data.add_document(document)
    end

    def remove_document(document)
      _data.remove_document(document)
    end
  end

  module Data
    def add_document(document)
      self.documents << document._data
      document._data
    end

    def get_documents()
      self.documents.map {|r| r.wrapper}
    end

    def remove_document(doc)
      rel = documents_rels.select { |dr| dr.start_vertex.kyck_id == doc.kyck_id }.first
      rel.remove if rel
    end

    def get_document_by_id(document_id)
      get_documents.select {|l| l.kyck_id == document_id}.first
    end
  end
end

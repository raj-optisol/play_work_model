require 'factory_girl'

FactoryGirl.define do
  sequence(:doc_title) {|n| "Document#{n}"}

  factory :document, class: DocumentData do
    title {FactoryGirl.generate :doc_title}
    file_name 'image'
    kind :other
    status :not_reviewed
    url 'http://images.com/image.pdf'
  end
end

def create_document_for_user(user, attrs={})
  dd = FactoryGirl.build(:document, attrs)
  dd.owner = user._data
  dd.save!
  DocumentRepository.find(dd.id)
end



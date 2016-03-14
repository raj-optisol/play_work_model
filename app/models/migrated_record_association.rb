class MigratedRecordAssociation < ActiveRecord::Base
  attr_accessible :association_name, :migrated_record_id, :referential_migrated_record_id, :successful
  belongs_to :migrated_record
  belongs_to :referential_migrated_record, class_name: "MigratedRecord"
  validates :association_name, presence: true
end

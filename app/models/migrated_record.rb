class MigratedRecord < ActiveRecord::Base
  attr_accessible :kyck_id, :original_id, :original_type
  validates :kyck_id, presence: true
  validates :original_id, presence: true
  validates :original_type, presence: true
  has_many :migrated_record_associations
  has_many :duplicate_migrated_records
end

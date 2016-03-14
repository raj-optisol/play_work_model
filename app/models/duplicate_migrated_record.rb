class DuplicateMigratedRecord < ActiveRecord::Base
  attr_accessible :additional_id, :migrated_record_id
  belongs_to :migrated_record
  
end

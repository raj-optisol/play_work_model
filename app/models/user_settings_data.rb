class UserSettingsData < ActiveRecord::Base
  self.table_name = 'user_settings'

  attr_accessible :id, :user_id
  # attr_accessible :settings, type: :hstore
  serialize :settings, ActiveRecord::Coders::Hstore
  
  validates_uniqueness_of :user_id
  
end

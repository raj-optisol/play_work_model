class PublisherEvent  < ActiveRecord::Base
  self.table_name = 'events'

  attr_accessible :id, :name, :content, :type, :published, :created_at, :updated_at
  serialize :content, JSON
end

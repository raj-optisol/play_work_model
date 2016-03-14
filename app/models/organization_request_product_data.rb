class OrganizationRequestProductData < ActiveRecord::Base
  include ActiveUUID::UUID
  include Empowerable::Data
  self.primary_key = "id"
  self.table_name = 'organization_request_products'

  attr_accessible :kind, :amount
  
  validates :kind, uniqueness: true, presence: true
  

end

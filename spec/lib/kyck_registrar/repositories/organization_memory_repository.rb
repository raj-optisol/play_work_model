module OrganizationMemoryRepository
 

  def self.persist(org)
    org.id ||= UUIDTools::UUID.random_create

    orgs << org

    org
  end

  def self.find(id)

    orgs.select do |u|
      u.id == id
    end

    orgs.first
  end

  def self.truncate
    orgs = []
  end

  private

  def self.orgs
    @orgs ||= [] 
  end
end

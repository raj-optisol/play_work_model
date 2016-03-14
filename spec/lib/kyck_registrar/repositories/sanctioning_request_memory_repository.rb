module SanctioningRequestMemoryRepository

  def self.persist(org_request)
    org_request.id = org_requests.count if org_request.id.nil?

    org_requests << org_request

    org_request
  end

  def self.find(id)
    org_requests.select do |u|
      u.id == id
    end

    org_requests.first
  end

  private

  def self.org_requests
    @org_requests ||= [] 
  end
end

require 'uuidtools'

module UserMemoryRepository
 

  def self.persist(user)
    user.id ||= UUIDTools::UUID.random_create

    users << user

    user
  end

  def self.find_by_email(email)
    users.select do |u|
      u.email == email
    end.first
  end

  def self.find(id)

    users.select do |u|
      u.id == id
    end.first

  end

  def self.all
    users
  end

  def self.truncate
    @users = []
  end

  private

  def self.users
    @users ||= [] 
  end
end

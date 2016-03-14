module Users
  class Organization < SimpleDelegator
    attr_accessor :user_id
  end
end

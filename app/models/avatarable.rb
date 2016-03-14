module Avatarable
  module Data

    def self.included(base)
      base.extend(ClassMethods) 
    end

    def avatar?
      return false  if self.avatar.blank?
      default = self.class._props[:avatar][:default]
      return false if default && self.avatar.match(default)
      return true
    end

    def avatar_version
      self.avatar_doc and self.avatar_doc["version"] 
    end

    module ClassMethods
      def has_avatar(property_name={}, default_avatar=nil)
        property :avatar, default: default_avatar
        property :avatar_uri, type: :string
        property :avatar_version, type: :string
      end
    end
  end
end

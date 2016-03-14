require 'active_model'
require 'oriented'
require 'hooks'

module BaseModel

  module Model
    extend Forwardable
    include ActiveModel::Naming
    include ActiveModel::Conversion

    def_delegator :_data, :id
    def_delegator :_data, :props, :attributes
    def_delegator :_data, :update_attributes
    def_delegator :_data, :updated_at
    def_delegator :_data, :created_at
    def_delegator :_data, :kyck_id
    def_delegator :_data, :kyck_id=
    def_delegator :_data, :migrated_id
    def_delegator :_data, :migrated_id=
    def_delegator :_data, :valid?
    def_delegator :_data, :to_partial_path
    def_delegator :_data, :to_key
    def_delegator :_data, :to_param
    def_delegator :_data, :errors

    def self.included(base)
      base.extend(ActiveModel::Naming)
      base.extend(ActiveModel::Conversion::ClassMethods)
    end


    def persisted?
      _data.persisted?
    end

    def permissions
      @permissions ||= []
    end

    def permissions=(value)
      @permissions = value
    end

    def viewable_by?(user, rels=[])
      true
    end


    def available_permission_sets
      []
    end


    def count(label)
      return 0 unless self.persisted?
      self._data.send(label).count
    end

    def to_param
      kyck_id
    end

  end

  class Data
    include Oriented::Vertex
    include Hooks
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveSupport::Concern

    def self.included(base)
      base.extend(ActiveModel::Naming)
      base.extend(ActiveModel::Conversion::ClassMethods)
    end

    define_hook :before_save
    before_save :generate_timestamp
    before_save :generate_kyck_id

    property :kyck_id, index: :exact
    property :migrated_id
    property :updated_at, type: Fixnum
    property :created_at, type: Fixnum

    def self.relationship_label_for(relationship)
      return nil unless self._rels[relationship]
      self._rels[relationship].label
    end

    def reload
      __java_obj.record.reload if __java_obj
      self
    end

    def save
      run_hook :before_save
      super
    end

    def save!
      run_hook :before_save
      super
    end

    def model_wrapper

      model_class = Edr::Registry.model_class_for self.class
      m = model_class.new.tap do |m|
        m.send(:_data=, self)
      end
      m
    end

    protected

    def generate_timestamp
      self.created_at = Time.now.utc.to_i unless created_at
      self.updated_at = Time.now.utc.to_i
    end
    def generate_kyck_id
      self.kyck_id = UUIDTools::UUID.random_create.to_s unless self.kyck_id
    end

  end
end

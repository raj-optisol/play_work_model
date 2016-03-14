module BaseModelRepository
  extend Edr::AR::Repository
  extend CommonFinders::OrientGraph
  set_model_class BaseModel::Model
  def self.wrap data
    model_class = Edr::Registry.model_class_for(data.class)
    model_class.new.tap do |m|
      m.send(:_data=, data)
      m.send(:repository=, self)
    end
  end
end

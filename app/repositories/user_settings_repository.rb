module UserSettingsRepository
  extend Edr::AR::Repository
  extend CommonFinders::ActiveRecord  
  set_model_class UserSettings

  def self.get_or_create(user, settings={})
    obj = where(user_id: user.kyck_id).first
    if !obj
      uset = settings.delete(:settings)
      obj = data_class.klass.create(settings.merge({user_id:user.kyck_id}))
      if uset      
        obj.settings = uset 
        obj.save
      end
    end
    obj
    
    
  end

  # def self.get_order_items obj, attrs={}, opts={}
  #   opts = {order: "id desc", limit: 25, offset: 0}.merge(opts)
  #   attrs = {:order_id=>obj.id}.merge(attrs)
  #   OrderItemRepository.find_by_attrs(attrs, opts)    
  # end
  # 
  # def self.get_sum obj, attrs={}, opts={}
  #   attrs = {:order_id=>obj.id}.merge(attrs)
  #   OrderItemRepository.get_sum(attrs, opts)
  # end
  # 
  # def self.update_order_items obj, update_attrs={}, attrs={}
  #   attrs = {:order_id=>obj.id}.merge(attrs)
  #   OrderItemRepository.update_order_items(attrs, update_attrs)
  # end
  

    
end

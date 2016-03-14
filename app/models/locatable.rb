module Locatable

  module Model

    def get_locations()
      wrap _data.get_locations()
    end


    def add_location(location)
      wrap _data.add_location(location)  
    end

    %w(address1 address2 city state zipcode country).each do |attr|
      define_method attr do
        return if locations.empty?
        locations.first.public_send(attr)
      end
    end

    def remove_location(loc)
      _data.remove_location(loc) 
    end
  end

  module Data
    def add_location(location)
      self.locations << location._data
      location._data
    end

    def get_locations()
      self.locations.map {|r| r.wrapper}
    end

    def remove_location(location)
      rel = get_location_by_id(location.kyck_id)
      rel.destroy if rel
    end


    def get_location_by_id(location_id)
      get_locations.select {|l| l.kyck_id == location_id}.first
    end

  end

end

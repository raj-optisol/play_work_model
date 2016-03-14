module OrganizationRepository
  module RegistrationRepository
    extend Edr::AR::Repository
    extend CommonFinders::OrientGraph
    set_model_class Registration

    def self.get_registrations(obj, opts={})
      get_items(obj, 'Season__registrations', opts)

    end

  end
end

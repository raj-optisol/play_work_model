class Importer
  class PlayerCreator
    attr_reader :requestor,
      :import_item,
      :roster

    def initialize(import_item)
      @import_item = import_item
      @roster      = import_item.roster
    end

    def execute!
      player_user
      # Don't create parent account
      # parent_user
      location
      documents
      avatar
      UserRepository.persist(player_user)
      true
    end

    private

    def player_user
      @player_user ||= begin
        user = User.build(player_user_attributes)
        user = UserRepository.persist user
        player = roster.add_player(user, {jersey_number: import_item.jersey_number})
        player = OrganizationRepository::PlayerRepository.persist player
        user
      end
    end

    def player_user_attributes
      @player_user_attributes ||= {
        phone_number: import_item.contact_phone,
        kyck_id: uuid,
        email: import_item.contact_email,
        first_name: import_item.first_name,
        last_name: import_item.last_name,
        gender: import_item.gender,
        birthdate: import_item.date_of_birth,
        middle_name: import_item.middle_name
      }
      # Use the mail for player not for parent
      # @player_user_attributes.delete(:email) if create_parent?
      @player_user_attributes
    end

    # def parent_user
    #   return nil unless create_parent?
    #   @parent_user ||= begin
    #     user = UserRepository.find_by_email(import_item.contact_email) || User.build(parent_user_attributes)
    #     user.add_user(player_user)
    #     UserRepository.persist user
    #   end
    # end

    # def parent_user_attributes
    #   @parent_user_attributes ||= {
    #     phone_number: import_item.contact_phone,
    #     email: import_item.contact_email,
    #     first_name: "Parent",
    #     last_name: import_item.last_name
    #   }
    # end

    def location
      @location ||= begin
        loc = Location.build(location_attributes)
        loc.name = "Main Address"
        loc = LocationRepository.persist loc
        player_user.add_location(loc)
        loc
      end
    end

    def location_attributes
      @location_attributes ||= {
        address1: import_item.address,
        city: import_item.city,
        state: import_item.state,
        zipcode: import_item.zip
      }
    end

    def documents
      puts "starting documents"
      document_urls.each do |type, url|
        puts "processing doc: #{type} - #{url}"
        if url
          document = Importer::Document.new(url, type).retrive
          puts "uploaded doc"
          document_params = document.to_kyck_document_params
          puts "got doc params"
          d = player_user.create_document(document_params)
          puts "added doc to user"
          puts "doc id: #{d.kyck_id}"
          import_item.organization.add_document(d) if type == :waiver
          puts "added do to org" if type == :wavier
          UserRepository.persist(player_user)
          puts "Saved player"
          DocumentRepository.persist(d)
          puts "Saved Doc"
        end
      end
    end

    def document_urls
      {
        waiver: import_item.waiver_url,
        proof_of_birth: import_item.pob_url
      }
    end

    def avatar
      avatar_url = import_item.image_url
      if avatar_url
        image = Importer::Document.new(avatar_url, :avatar).retrive
        avatar_params = image.to_kyck_avatar_params
        player_user.update_attributes avatar_params
        UserRepository.persist(player_user)
      end
    end

    def uuid
      @uuid ||= UUIDTools::UUID.random_create.to_s
    end

    def normalize_date(date)
      Chronic.time_class = Time.zone
      Chronic.parse(date.to_s)
    end

    # def create_parent?
    #   dob = import_item.date_of_birth
    #   email_age_threshold = 13.years.ago
    #   (email_age_threshold - dob) < 0 # older than 13
    # end
  end
end

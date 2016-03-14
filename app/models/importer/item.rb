require 'uri'

class Importer
  class Item
    MALE   = "m"
    FEMALE = "f"

    ATTRIBUTES = [
      :first_name,
      :middle_name,
      :last_name,
      :date_of_birth,
      :gender,
      :contact_email,
      :address,
      :city,
      :state,
      :zip,
      :contact_phone,
      :image_url,
      :waiver_url,
      :pob_url,
      :team_name,
      :jersey_number
    ].each { |attr| attr_reader attr }

    def initialize(data, org, teams, requestor)
      initialize_errors!
      @org       = org # shit
      @teams     = teams # shit
      @requestor = requestor # shit
      ATTRIBUTES.each do |attr|
        public_send "#{attr}=", data[attr]
      end
    end

    # begin shit that probably has no business here
    # ie has too much knowledge of what teams and rosters are
    def teams
      @teams
    end

    def requestor
      @requestor
    end

    def organization
      @org
    end

    def team
      # TODO: consider memoizing this
      if team_name.nil? || team_name.empty?
        teams.detect { |t| t.name == "Open Team" }
      else
        teams.detect { |t| t.name == team_name }
      end
    end

    def roster
      team.try :official_roster
    end
    # end shit that probably has no business here

    def save
      success = PlayerCreator.new(self).execute! if valid?
      success ? true : false
    rescue
      false
    end

    def to_h
      ATTRIBUTES.reduce({}) do |hash, attr|
        hash[attr] = public_send attr
        hash
      end.merge(errors.to_h)
    end

    def errors
      @errors ||= Errors.new
    end

    # FIXME: This is Hacky!
    def initialize_errors!
      [
        :contact_email,
        :contact_phone,
        :first_name,
        :last_name,
        :date_of_birth,
        :gender,
        :address,
        :city,
        :state,
        :zip
      ].each { |attr| add_error attr, "#{attr} can't be blank" }
    end

    [:contact_email].each do |attr|
      define_method "#{attr}=" do |value|
        instance_var = :"@#{attr}"
        instance_val = normalize value, :string, :downcase
        remove_errors_for attr
        instance_variable_set instance_var, instance_val
        validate attr, :presence, :email
        instance_val
      end
    end

    # begin setters
    def first_name=(value)
      remove_errors_for :first_name
      @first_name = normalize value
      validate :first_name, :presence
    end

    def last_name=(value)
      remove_errors_for :last_name
      @last_name = normalize value
      validate :last_name, :presence, :no_player_matches
    end

    def middle_name=(value)
      @middle_name = normalize value
    end

    def date_of_birth=(value)
      remove_errors_for :date_of_birth
      @date_of_birth = normalize value, :string, :date
      validate :date_of_birth, :presence, :no_player_matches
    end

    def gender=(value)
      mf = normalize value, :string, :chr, :downcase
      remove_errors_for :gender
      if mf == "m"
        @gender = :male
      elsif mf == "f"
        @gender = :female
      else
        @gender = mf
      end
      validate :gender, :male_female
    end

    def address=(value)
      remove_errors_for :address
      @address = normalize value
      validate :address, :presence
    end

    def city=(value)
      remove_errors_for :city
      @city = normalize value
      validate :city, :presence
    end

    def state=(value)
      remove_errors_for :state
      @state = normalize value
      validate :state, :presence
    end

    def zip=(value)
      remove_errors_for :zip
      @zip = normalize value
      validate :zip, :presence
    end

    def contact_phone=(value)
      remove_errors_for :contact_phone
      @contact_phone = normalize value, :string, :digit_regex
      validate :contact_phone, :presence, :phone
    end

    def image_url=(value)
      remove_errors_for :image_url
      @image_url = normalize value
      validate :image_url, :url
    end

    def waiver_url=(value)
      remove_errors_for :waiver_url
      @waiver_url = normalize value
      validate :waiver_url, :url
    end

    def pob_url=(value)
      remove_errors_for :pob_url
      @pob_url = normalize value
      validate :pob_url, :url
    end

    def team_name=(value)
      remove_errors_for :team_name
      @team_name = normalize value
      # TODO: rethink naming
      validate :team_name, :team_name_exact, :room_on_roster
    end

    def jersey_number=(value)
      remove_errors_for :jersey_number
      @jersey_number = normalize value, :int, :string
      validate :jersey_number, :positive_int
    end
    # end setters

    # begin validation stuff that should be extracted
    def valid?
      errors.none?
    end

    def validate(attr, *args)
      value = public_send attr
      args.each do |arg|
        send("validate_#{arg}", attr, value)
      end
    end

    def validate_presence(attr, value)
      if value.nil?# || value.empty?
        add_error attr, "#{attr.to_s.humanize} can't be blank"
      end
    end

    def validate_url(attr, value)
      if !value.nil? && invalid_url?(value)
        add_error attr, "#{attr.to_s.humanize} must be a valid url"
      end
    end

    def validate_positive_int(attr, value)
      if value && non_positive_int?(value)
        add_error attr, "#{attr.to_s.humanize} must be a number greater than or equal to 0"
      end
    end

    def validate_team_name_exact(attr, value)
      if !value.nil? && no_team_match?(value)
        add_error attr, "#{attr.to_s.humanize} #{value} must match a team name exactly"
      end
    end

    def validate_room_on_roster(attr, value)
      if !value.nil? && roster_full?
        add_error attr, "#{attr.to_s.humanize} #{value} is at capacity"
      end
    end

    def validate_male_female(attr, value)
      if ![:male, :female].include? value
        add_error attr, "#{attr.to_s.humanize} must be either male or female"
      end
    end

    def validate_no_player_matches(attr, value)
      if possible_player_match?
        add_error :general, "player may be a duplicate"
      end
    end

    def validate_email(attr, value)
      if value.nil? || missing_at_sign?(value) || too_short_for_email?(value)
        add_error attr, "#{attr.to_s.humanize} must be a valid email"
      end
    end

    def validate_phone(attr, value)
      if value.nil? || too_short_for_phone?(value)
        add_error attr, "#{attr.to_s.humanize} must be a valid phone number"
      end
    end
    # end validation stuff

    # begin normalization stuff that should be extracted
    def normalize(value, *args)
      args = [:string] if args.length == 0
      args.reduce(value) do |string, arg|
        send("normalize_#{arg}", string)
      end
    end

    def normalize_string(string)
      return_string = string.to_s.strip
      if return_string.empty?
        nil
      else
        return_string
      end
    end

    def normalize_downcase(string)
      return_string = string.to_s.downcase
      if return_string.empty?
        nil
      else
        return_string
      end
    end

    def normalize_chr(string)
      return_string = string.to_s.chr
      if return_string.empty?
        nil
      else
        return_string
      end
    end

    def normalize_int(string)
      if string.nil? || string.empty?
        nil
      else
        string.to_i
      end
    end

    def normalize_date(string)
      if string.nil? || string.empty?
        nil
      else
        Chronic.time_class = Time.zone
        hacked_string_for_chronic = string.gsub(/(\/|\-)00/, '\12000')
        Chronic.parse(hacked_string_for_chronic)
      end
    end

    def normalize_digit_regex(string)
      if string.nil? || string.empty?
        nil
      else
        string.gsub /\D/, ''
      end
    end
    # end normalization stuff

    # TODO: should these question methods be here or somewhere else?
    def valid_url?(url)
      uri = URI url.to_s
      %w(http https).include?(uri.scheme) ? true : false
    rescue URI::InvalidURIError
      false
    end

    def invalid_url?(url)
      !valid_url?(url)
    end

    def no_team_match?(team_name)
      !team_match?(team_name)
    end

    def team_match?(team_name)
      (team_name && !team) ? false : true
    end

    def positive_int?(number)
      number.to_i >= 0 ? true : false
    rescue ArgumentError, TypeError, NoMethodError
      false
    end

    def missing_at_sign?(email)
      !email.include? "@"
    end

    def too_short_for_email?(email)
      email.length < 6 # a@b.co
    end

    def too_short_for_phone?(phone)
      phone.length < 7
    end

    def non_positive_int?(number)
      !positive_int?(number)
    end

    def roster_full?
      return false if is_open_team?
      roster.try(:player_count).to_i >= 26
    end

    def is_open_team?
      roster.try(:team).try(:name) == "Open Team"
    end

    def possible_player_match?
      if last_name && date_of_birth
        sql = "select from (select expand(in('plays_for')) from (traverse out_Organization__teams, out_Team__rosters from #{@org._data.id})) where last_name.toLowerCase() = \"#{last_name.downcase}\" and birthdate = '#{date_of_birth.to_date}'" # PARALLEL"
        cmd = OrientDB::SQLCommand.new(sql)
        possible_match_count = Oriented.graph.command(cmd).execute.count
        possible_match_count > 0
      else
        false
      end
    end

    def add_error(attr, message)
      errors.add_error(attr, message)
    end

    def remove_errors_for(attr)
      errors.remove_errors_for(attr)
    end
  end
end

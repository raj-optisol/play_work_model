module CardRepresenter
  include Roar::Representer::JSON
  #include Representable::Cache
  include HasDocuments::Presenter

  property :id
  property :carded_user, :as => :user, extend: UserRepresenter
  property :expires_on
  property :processed_on
  property :approved_on
  property :created_at
  property :org_name
  property :org_state
  property :message_status
  property :status

  property :kind, getter: -> args {I18n.t("activerecord.symbolizes.card_data.kind.#{kind}")}
  #TODO: This is here b/c CardStatus uses it and the same UI uses card statues and cards
  property :card_type, getter: -> args {I18n.t("activerecord.symbolizes.card_data.kind.#{kind}")}
  property :first_name
  property :last_name
  property :middle_name
  property :full_name
  property :birthdate, getter: lambda { |*|
    _data.birthdate.strftime("%m-%d-%Y") if _data && _data.birthdate
  }
  property :order_id
  property :sanctioning_body_id
  property :avatar_url
  property :background_check

  property :carded_for, :extend => Module.new {
    include Representable::JSON;
    include HasAvatar::Presenter
    include HasClassName::Presenter
    property :name
    property :kind    
    property :id, getter: lambda{|*| self.kyck_id }
    property :rid, getter: lambda{|*| self._data.id }
    property :link, getter: lambda{|*| organization_path(self)}
  }

  property :processor, :extend => Module.new {
    include Representable::JSON;
    include HasAvatar::Presenter
    include HasClassName::Presenter
    property :name
    property :id, getter: lambda{|*| self.kyck_id }
    property :rid, getter: lambda{|*| self._data.id }
    property :link, getter: lambda{|*| competition_path(self)}
  }

  collection :teams, :if => lambda { |opts| opts[:with_teams].to_s == "true" }, class: Team do
    property :id, :getter => lambda {|*| self.kyck_id.to_s}
    property :name
  end

  #representable_cache cache_key: [:id, :updated_at, 'card_cache_key']

  def avatar_url(opts={format: :png})
    return self.user.avatar_url if self && self.user
    "https://res.cloudinary.com/kyck-com/image/upload/user_avatar_syy1gy.png"
  end

  def id
    self.kyck_id
  end

  def user
    self.carded_user.extend(UserRepresenter) if self.carded_user
  end

  # Need a better way to access this information
  def background_check
    return unless kind == :staff
    user.background_check
  end

  def sanctioning_body_id
    return unless self && self.sanctioning_body
    self.sanctioning_body.kyck_id
  end

  def org_name
    self.carded_for.name if self.carded_for && self.carded_for.name
  end

  def org_state
    self.carded_for.state if self.carded_for && self.carded_for.state
  end

  def processor_avatar_url
    if processor
      return "http://res.cloudinary.com/kyck-com/image/upload/v1423245360/avatar_no_image_300x300_rih70d.png" unless self.processor.avatar
      Cloudinary::Utils.cloudinary_url(self.processor.avatar, {secure: true, format: :png})
    end
  end

  def carded_for_obj
    return unless self.carded_for

    rep = case self.carded_for
          when Organization
            OrganizationRepresenter
          when SanctioningBody
            SanctioningBodyRepresenter
          when Team
            TeamRepresenter
          end
    self.carded_for.extend(rep)
  end

  def doc_type(tp)

    docs = self.documents.select do |doc|
      doc.kind == tp
    end

    if self.carded_user
      docs = self.carded_user.documents.select do |doc|
        doc.kind == tp
      end if docs.empty?
    end

    ((docs.sort {|d| d.created_at}.last) || Null::Document.new)
  end

  def teams
    return [] unless carded_for && carded_user
    case self.kind
    when :player
      sql = 'select from (select expand(in("Team__rosters")) from ' \
        ' (select expand(out("plays_for")) from ' \
        "#{carded_user._data.id}))" \
        " where in_Organization__teams.@rid = '#{self.carded_for._data.id}'"
    when :staff
      sql = 'select from (select expand(out("staff_for")) ' \
        "from #{carded_user._data.id}) where @class='Team' " \
        " and in_Organization__teams.@rid = '#{carded_for._data.id}'"
    end
    # puts sql
    tms = []
    begin
      cmd = OrientDB::SQLSynchQuery.new(sql)
      tms = Oriented.graph.command(cmd).execute.collect{|t| t.wrapper.model_wrapper}
    rescue => e
      puts "ERROR: #{e.inspect}"
      tms = []
    end
    tms
  end

  def card_cache_key
    if Flip.on? :cache_card
      "#{kyck_id}-#{updated_at}"
    else
      Time.now.to_i
    end
  end
end

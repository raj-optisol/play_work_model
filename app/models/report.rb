require 'csv'

class Report
  include CardRepository

  def initialize( months = [],year=2015)
    @year = year
    @months = months
    @items = []
    @users = []
  end

  def run(batch_size = 2000, options = {})
    log("############### #{Time.now} ###############")
    @months.each do |m|
      m.upcase!
      log("********** #{m} **********")
      execute(m, timestamp(m, :start), timestamp(m, :finish), batch_size, options)
      log('********** DONE **********')
    end
    log("############### #{Time.now} ###############")
  end

  def recompete(card_ids)
    CSV.open('MISSING-COMPETITIONS.csv', 'wb') do |csv|
      csv << ['Card ID', 'Competition ID', 'Competition Name']
      card_ids.each do |ci|
        card = CardRepository.find(kyck_id: ci)
        next unless card

        team = grab_team(card.carded_user, card.kind, card.carded_for.kyck_id)
        next unless team

        comp = team.competition_entries.map { |c| c.competition } .first
        csv << [ci, comp ? comp.kyck_id : '', comp ? comp.name : '']
      end
    end
  end

  private

  def execute(month, start, finish, batch_size, options = {})
    CSV.open("REGISTRATION-REPORT-#{month}.csv", 'wb') do |csv|
      csv << headers
      page = 0

      loop do
        records = gimme_data(start, finish, batch_size, page * batch_size, options)
        @items = lookup_items(records, month)
        puts @items.count
        puts "DONE"
        @users = lookup_users(records)

        records.each { |r| csv << normalize(r) }

        page += 1
        log("----- #{record_display(records.count, page, batch_size)} -----")
        break if records.size < batch_size
      end
    end
  end

  def record_display(total, page, batch_size)
    page_total = total > batch_size ? (total / batch_size).to_i : 1

    page_record_total = total < batch_size ? total : batch_size

    total == 0 ? "NO RECORDS FOUND": "PAGE #{page}"
  end

  def gimme_data(start, finish, batch_size, offset, options)
    start = Time.at(start)
    finish = Time.at(finish)

    records = CardRepository.approved_in_span(start, finish, batch_size, offset)
    records_array = []

    records.each do |record|
      record_hash = Hash.new

      record_hash['card_id'] = record.kyck_id rescue ''
      record_hash['user_id'] = record.carded_user.kyck_id rescue ''
      record_hash['first_name'] = record.first_name rescue ''
      record_hash['middle_name'] = record.middle_name rescue ''
      record_hash['last_name'] = record.last_name rescue ''
      record_hash['birthdate'] = record.birthdate rescue ''
      record_hash['type'] = record.kind rescue ''
      record_hash['approved_on'] = record.approved_on rescue ''
      record_hash['expires_on'] = record.expires_on rescue ''
      record_hash['organization_id'] = record.carded_for.kyck_id rescue ''
      record_hash['organization_name'] = record.carded_for.name rescue ''
      record_hash['competition_id'] = record.processor.kyck_id rescue ''
      record_hash['competition_name'] = record.processor.name rescue ''
      record_hash['age_group'] = record.carded_user.plays_for.map{|r| r.team.age_group } rescue []
      record_hash['uscs_sales_rep'] = record.carded_for.uscs_rep.name rescue ''

      if options[:age_group]
        next unless record_hash['age_group'].include?(options[:age_group])
      end

      if options[:uscs_sales_rep]
        next unless record_hash['uscs_sales_rep'] != options[:uscs_sales_rep]
      end

      records_array << record_hash
    end

    records_array
  end

  def lookup_items(records, month)
    card_ids = records.map { |r| r['card_id'] } .compact.uniq

    return [] if card_ids.empty?

    month = futurestamp(month)
    year =  month.downcase == "jan" ? (@year.to_i + 1).to_s : @year
    
    OrderItemData.includes(:order).where("orders.submitted_on < '1 #{month} #{year}' and order_items.item_id in ('#{card_ids.join("', '")}')" ).order('orders.submitted_on DESC')
  end

  def lookup_users(records)
    user_ids = records.map { |r| r['user_id'] } .compact.uniq
    sql = "select from user where kyck_id in ['#{user_ids.join("', '")}']"

    cmd = OrientDB::SQLCommand.new(sql)
    res = Oriented.graph.command(cmd).execute
    res.map { |u| u.wrapper.model_wrapper }.to_a
  end

  def normalize(record)
    item = grab_item(record['card_id'])
    user = grab_user(record['user_id'])
    parent = user ? user.owners.first : nil
    team = grab_team(user, record['type'], record['organization_id'])
    location = user ? user.locations.first : nil
    location ||= parent ? parent.locations.first : nil

    [
      record['card_id'],
      record['user_id'],
      record['first_name'],
      record['middle_name'],
      record['last_name'],
      dateify(record['birthdate'], true),
      user ? user.gender : '',
      user ? user.email : '',
      parent ? parent.email : '',
      location ? location.address1 : '',
      location ? location.address2 : '',
      location ? location.city : '',
      location ? location.state : '',
      location ? location.zipcode : '',
      user ? user.phone_number : '',
      record['type'],
      item ? item.amount : '',
      dateify(record['approved_on']),
      dateify(record['expires_on']),
      item ? dateify(item.order.submitted_on) : '',
      record['organization_id'],
      record['organization_name'],
      item ? item.order.state : '',
      team ? team.kyck_id : '',
      team ? team.name : '',
      record['age_group'].uniq.join(","),
      record['competition_id'],
      record['competition_name'],
      item ? item.order_id : '',
      record['uscs_sales_rep']
    ]
  end

  def grab_item(card_id)
    return unless card_id

    @items.find { |i| i.item_id.to_s == card_id.to_s }
  end

  def grab_user(user_id)
    return unless user_id

    @users.find do |user|
      kyck_id = nil
      if user.is_a?(User)
        kyck_id = user.kyck_id
      else
        kyck_id = user.wrapper.kyck_id
      end
      kyck_id.to_s == user_id.to_s
    end
  end

  def grab_team(user, type, org_id)
    return unless user && type && org_id
    return if type.to_s.downcase == 'staff'

    teams = user.plays_for.map { |r| r.team } .compact.uniq { |t| t.kyck_id }
    teams.reject! { |t| t.class != Team || t.organization.nil? }
    return if teams.empty?
    teams.find { |t| t.organization.kyck_id.to_s == org_id.to_s }
  end

  def headers
    [
      'Card ID',
      'User ID',
      'User First Name',
      'User Middle Name',
      'User Last Name',
      'User Birthdate',
      'User Gender',
      'User Email',
      'Parent Email',
      'User Address 1',
      'User Address 2',
      'User City',
      'User State',
      'User Zipcode',
      'User Phone Number',
      'Card Type',
      'Card Amount',
      'Approved On',
      'Expires On',
      'Submitted On',
      'Organization ID',
      'Organization Name',
      'Organization State',
      'Team ID',
      'Team Name',
      'Age Group',
      'Competition ID',
      'Competition Name',
      'Order ID',
      'USCS Sales Rep'
    ]
  end

  def timestamp(month, point)
    d = DateTime.strptime("1 #{month} #{@year}", '%e %b %Y')

    return d.to_time.to_i if point == :start
    (d + 1.month).to_time.to_i
  end

  def futurestamp(month)
    d = DateTime.strptime("1 #{month} #{@year}", '%e %b %Y')
    (d + 1.month).strftime('%b').upcase
  end

  def dateify(date, is_odb = false)
    return '' unless date
    d = date

    d = Time.at(date.to_i).to_datetime unless is_odb

    d.strftime('%m/%d/%Y')
  end

  def odb_timestamp(date)
    date.strftime("%m/%d/%Y")
  end

  def log(message)
    puts message
  end
end

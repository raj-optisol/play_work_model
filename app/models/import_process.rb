class ImportProcess < ActiveRecord::Base
  include Symbolize::ActiveRecord
  attr_reader :file_store
  attr_accessible :organization_id, :user_id, :file_name, :successful_row_count, :error_row_count, :status
  has_many :import_messages, dependent: :destroy, primary_key: :kyck_id
  before_create :generate_guid
  always_background :execute

  def initialize(*args)
    super
    @ts = Time.now.strftime('%Y-%m-%d-%H%M%S')
    @file_store = ::KyckFileStore.new(Settings.kyck_csv_file_store_options.to_h)
  end

  symbolize :status, in: [:running, :complete, :failed]

  def file_suffix
    File.join(organization_id.to_s, @ts, file_name)
  end

  def file_content
    file_store.get_string_io(file_suffix)
  end

  def to_param
    kyck_id.to_s
  end

  def execute
    self.status = :running
    self.save

    begin
      csv_source = SmarterCSV.process(file_content, row_sep: :auto)
      reporter = KyckRegistrar::Import::ActiveRecordReporter.new(self.kyck_id.to_s)
      club = OrganizationRepository.find(kyck_id: self.organization_id.to_s)
      requestor = UserRepository.find(kyck_id: self.user_id)
      import_csv = KyckRegistrar::Import::ImportCSV.new(club, requestor, csv_source)
      import_csv.reporter = reporter
      import_csv.subscribe(self)
      import_csv.execute

      self.status = :complete
      self.save
    rescue => ex
      on_error(ex)
    ensure
      Oriented.close_connection
    end
  end

  def get_row_sep
    lines = File.open(file_path).first(10)
    if lines.select {|l| l =~ /\r/}.any?
      "\r"
    else
      "\n"
    end
  end

  def successful_row(row)
    Rails.logger.info("** ImportProcess successful row")
    self.successful_row_count += 1
  end

  def error_row(row, err)
    Rails.logger.info("** ImportProcess error row")
    Raven.capture_exception(err)
    self.error_row_count += 1
  end

  def on_error(ex)
    Rails.logger.info("** ImportProcess ERROR: #{ex}")
    Raven.capture_exception(ex)
    self.status = :error
    self.save
  end

  private

  def generate_guid
    self.kyck_id ||= UUIDTools::UUID.random_create
  end
end

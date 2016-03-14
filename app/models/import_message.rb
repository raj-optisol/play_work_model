class ImportMessage < ActiveRecord::Base
  include Symbolize::ActiveRecord
  belongs_to :import_process, foreign_key: "kyck_id"

  attr_accessible :message, :kind, :row_id

  symbolize :kind, in: [:started, :ended, :error_row, :successful_row]
end

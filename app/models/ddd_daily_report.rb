class DddDailyReport < ActiveRecord::Base
  belongs_to :reporter, :class_name => 'User', :foreign_key => 'reporter_id'

  validates :date, uniqueness: {
    scope: [:reporter_id],
    message: Proc.new {
      I18n.t(:error_report_already_exists)
    }
  }
end

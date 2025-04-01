class DddDailyReportReceiver < ActiveRecord::Base
  belongs_to :receiver, :class_name => 'User', :foreign_key => 'receiver_id'

  validates :receiver_id, uniqueness: { scope: [:reporter_id] }
end

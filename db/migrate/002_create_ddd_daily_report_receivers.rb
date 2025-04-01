class CreateDddDailyReportReceivers < ActiveRecord::Migration[4.2]
  def change
    create_table :ddd_daily_report_receivers do |t|

      t.integer :reporter_id

      t.integer :receiver_id


    end

  end
end

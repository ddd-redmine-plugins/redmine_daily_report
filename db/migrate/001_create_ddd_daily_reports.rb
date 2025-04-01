class CreateDddDailyReports < ActiveRecord::Migration[4.2]
  def change
    create_table :ddd_daily_reports do |t|

      t.date :date

      t.integer :reporter_id

      t.text :plans_for_tomorrow

      t.text :concerns_and_risks

      t.text :other_comments

      t.datetime :created_on

      t.datetime :updated_on


    end

  end
end

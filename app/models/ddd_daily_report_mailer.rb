class DddDailyReportMailer < Mailer

  def on_report(user, report)
    @title = l(:label_daily_report_subject, :date => format_date(report.date), :reporter => report.reporter.try!(:login))
    @url = url_for(:controller => 'ddd_daily_reports', :action => 'show', :id => report.id)
    @timelogs = TimeEntry.where(user_id: report.reporter_id, spent_on: report.date).where.not(issue_id: nil)
    @report = report
    mail to: user, subject: @title
  end

  def self.deliver_on_report(report)
    users = User.where(id: DddDailyReportReceiver.where(reporter_id: report.reporter_id).pluck(:receiver_id))
    users.each do |user|
      on_report(user, report).deliver_later
    end
  end

end

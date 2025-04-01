class DddDailyReportsController < ApplicationController
  before_action :require_login
  before_action :find_report, :except => [:index, :new, :create, :add_receiver, :remove_receiver, :receivers, :update_timelogs, :timelogs]
  before_action :init_receivers, :except => [:add_receiver, :remove_receiver, :update_timelogs, :timelogs]

  helper :sort
  include SortHelper


  def index
    sort_init ['date', 'users.login']
    sort_update %w(ddd_daily_reports.id date users.login ddd_daily_reports.updated_on)

    reports = DddDailyReport.includes(:reporter)
    reports = reports.where(reporter_id: params[:search_reporter]) if params[:search_reporter].present?
    if params[:search_date_from].present? && params[:search_date_to].present?
      reports = reports.where(date: params[:search_date_from]..params[:search_date_to])
    elsif params[:search_date_from].present?
      reports = reports.where("date >= ?", params[:search_date_from])
    elsif params[:search_date_to].present?
      reports = reports.where("date <= ?", params[:search_date_to])
    end
    @report_count = reports.count
    @limit = per_page_option
    @report_pages = Paginator.new @report_count, @limit, params[:page]
    @offset ||= @report_pages.offset
    @reports = reports.order(sort_clause).limit(@limit).offset(@offset)
  end


  def new
    @report = DddDailyReport.new()
    @report.date = Date.current
    @report.reporter = User.current
    init_timelogs(@report.date, @report.reporter_id)
  end


  def create
    @report = DddDailyReport.new(params[:report].permit(:date, :reporter_id, :plans_for_tomorrow, :concerns_and_risks, :other_comments))
    if @report.save
      DddDailyReportMailer.deliver_on_report(@report)
      flash[:notice] = l(:notice_successful_create)
      redirect_to ddd_daily_report_path(@report.id)
    else
      init_timelogs(@report.date, @report.reporter_id)
      render :new
    end
  end


  def show
    init_timelogs(@report.date, @report.reporter_id)
  end


  def edit
    init_timelogs(@report.date, @report.reporter_id)
  end


  def update
    @report.attributes = params[:report].permit(:plans_for_tomorrow, :concerns_and_risks, :other_comments)
    if @report.save
      DddDailyReportMailer.deliver_on_report(@report)
      flash[:notice] = l(:notice_successful_update)
      redirect_to ddd_daily_report_path(@report.id)
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:error] = l(:notice_locking_conflict)
  end


  def destroy
    @report.destroy
    redirect_to ddd_daily_reports_path
  end


  def add_receiver
    @receiver = DddDailyReportReceiver.new(params[:receiver].permit(:reporter_id, :receiver_id));
    @receiver.save
    redirect_to receivers_ddd_daily_reports_path
  end


  def remove_receiver
    @receiver = DddDailyReportReceiver.find_by_id(params[:id])
    @receiver.destroy if @receiver
    redirect_to receivers_ddd_daily_reports_path
  end


  def receivers
  end


  def update_timelogs
    # logger.debug(params.to_json)
    errors = []
    failed = []
    if params[:add]
      # 作業時間の追加
      if params[:new_timelog][0][:issue_id].present?
        # ※ project_id は補完してくれる模様
        # ※ 時間が空欄だと登録できず、エラーを通知する方法が不明のため、空欄の場合は 0 で登録
        # 　 ※ エラーの通知は解決したけど、そのままにしておく
        timelog = TimeEntry.new(params[:new_timelog][0].permit(:issue_id, :activity_id, :comments, :hours))
        if User.current.allowed_to?(:log_time, Issue.find_by_id(timelog.issue_id).try!(:project))
          timelog.spent_on = params[:spent_on]
          timelog.user_id = params[:reporter_id]
          timelog.hours ||= 0
          if !timelog.save
            timelog.errors.full_messages.each {|message| errors << message}
          end
        else
          errors << l(:error_unable_add_timelog, :id => "##{timelog.issue_id}")
        end
      else
        errors << l(:error_no_issue_selected_to_add_timelog)
      end
      flash[:timelog_add_errors] = errors
    elsif params[:update]
      # 作業時間の更新
      if params[:timelogs].present?
        params[:timelogs].each { |k, v|
          timelog = TimeEntry.find_by_id(k)
          if timelog.present? && timelog.editable_by?(User.current)
            timelog.safe_attributes = v.permit(:activity_id, :comments, :hours)
            timelog.hours ||= 0
            if !timelog.save
              timelog.errors.full_messages.each {|message| errors << message}
              failed << timelog.id
            end
          else
            # 当該データが存在しない場合を考慮して情報はリクエストパラメータから取得する
            errors << l(:error_unable_edit_timelog, :id => "##{v[:issue_id]}")
            failed << k.to_i
          end
        }
      end
      flash[:timelog_edit_errors] = errors.uniq
      flash[:timelog_failed_ids] = failed
    elsif params[:delete]
      # 作業時間の削除
      if params[:deletes].present?
        params[:deletes].each { |k, v|
          timelog = TimeEntry.find_by_id(k)
          if timelog.present? && timelog.editable_by?(User.current)
            if !timelog.destroy
              timelog.errors.full_messages.each {|message| errors << message}
              failed << timelog.id
            end
          else
            # 当該データが存在しない場合を考慮して情報はリクエストパラメータから取得する
            errors << l(:error_unable_delete_timelog, :id => "##{v}")
            failed << k.to_i
          end
        }
      else
        errors << l(:error_no_timelog_selected_to_delete)
      end
      flash[:timelog_edit_errors] = errors.uniq
      flash[:timelog_failed_ids] = failed
    end
    redirect_to timelogs_ddd_daily_reports_path(spent_on: params[:spent_on], reporter_id: params[:reporter_id])
  end


  def timelogs
    init_timelogs(params[:spent_on], params[:reporter_id])
  end


private
  def find_report
    @report = DddDailyReport.find_by_id(params[:id])
    render_404 unless @report
  end


  def init_receivers
    @receivers = DddDailyReportReceiver.where(reporter_id: User.current.id)
    @receiver_candidates = User.where(type: User.to_s, status: User::STATUS_ACTIVE)
      .where.not(id: @receivers.pluck(:receiver_id))
      .order(login: 'ASC')
    @receiver = DddDailyReportReceiver.new()
    @receiver.reporter_id = User.current.id
  end

  def init_timelogs(spent_on, reporter_id)
    # 登録済みの作業時間
    # ※ チケットに紐付いていない作業時間は除外する
    @timelogs = TimeEntry.where(user_id: reporter_id, spent_on: spent_on).where.not(issue_id: nil)
    # 作業時間追加用のチケット選択肢
    # ※ 報告者がウォッチしているものを更新日時降順でソート、チケットのタイトルをツールチップに表示
    # ※ ログインユーザに作業時間の追加が許可されていないチケットは非活性にする
    watched = Watcher.select(:watchable_id).where(watchable_type: 'Issue', user_id: reporter_id)
    @issue_select_options = [['', '']]
    Issue.where(id: watched).order(updated_on: 'DESC').each { |i|
      allowed = User.current.allowed_to?(:log_time, i.project)
      # @issue_select_options << [allowed ? "##{i.id}" : "##{i.id}*", i.id, {title: i.subject}]
      @issue_select_options << ["##{i.id}", i.id, {title: i.subject, disabled: !allowed}]
    }
    # 作業時間追加用の器
    @new_timelog = TimeEntry.new()
    # 日報の日付
    @spent_on = spent_on
    # 報告者
    @reporter_id = reporter_id
  end

end

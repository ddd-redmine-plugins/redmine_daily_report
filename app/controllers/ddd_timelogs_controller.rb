class DddTimelogsController < ApplicationController
  before_action :require_login
  before_action :init_parameters, :only => [:index]

  helper :sort
  include SortHelper

  def index
    sort_init ['spent_on']
    sort_update %w(spent_on)

    time_entries = TimeEntry.all()
    # 日付、ユーザ、チケットによるフィルタ
    if params[:search_date_from].present? && params[:search_date_to].present?
      time_entries = time_entries.where(spent_on: params[:search_date_from]..params[:search_date_to])
    elsif params[:search_date_from].present?
      time_entries = time_entries.where("spent_on >= ?", params[:search_date_from])
    elsif params[:search_date_to].present?
      time_entries = time_entries.where("spent_on <= ?", params[:search_date_to])
    end
    time_entries = time_entries.where(user_id: params[:search_user] || @default_search_user)
    # チケットに紐付いていない作業時間は除外する
    time_entries = time_entries.where.not(issue_id: nil)
    # ここまでの検索結果からチケットの選択肢を用意する
    issue_ids = time_entries.select(:issue_id).distinct.pluck(:issue_id)
    @options_for_search_issue = Issue.where(id: issue_ids).order(updated_on: 'DESC')
      .map { |i| ["##{i.id}", i.id, {title: i.subject}] }
    # チケットの選択
    time_entries = time_entries.where(issue_id: params[:search_issue])
    # チケット ID のリスト(列見出し)を取得
    @issue_ids = time_entries.select(:issue_id).distinct.pluck(:issue_id).sort
    # 日付でページング
    dates = time_entries.select(:spent_on).distinct
    @date_count = dates.count
    @limit = per_page_option
    @date_pages = Paginator.new @date_count, @limit, params[:page]
    @offset ||= @date_pages.offset
    @date_entries = dates.limit(@limit).offset(@offset).order(sort_clause)
    # 現ページの日付で抽出
    @time_entries = time_entries.where(spent_on: @date_entries.pluck(:spent_on)).order(sort_clause)
      .to_a
      .group_by { |m| m.spent_on }
      .map { |key, value| [key, value.group_by { |v| v.issue_id }] }
  end

  def update_issues
    redirect_to issues_ddd_timelogs_path(
      search_date_from: params[:hidden_date_from],
      search_date_to: params[:hidden_date_to],
      search_user: params[:hidden_user],
      search_issue: params[:hidden_issue].split(',')
    )
  end

  def issues
    # 日付とユーザの指定に応じたチケット選択肢を抽出
    time_entries = TimeEntry.all()
    if params[:search_date_from].present? && params[:search_date_to].present?
      time_entries = time_entries.where(spent_on: params[:search_date_from]..params[:search_date_to])
    elsif params[:search_date_from].present?
      time_entries = time_entries.where("spent_on >= ?", params[:search_date_from])
    elsif params[:search_date_to].present?
      time_entries = time_entries.where("spent_on <= ?", params[:search_date_to])
    end
    time_entries = time_entries.where(user_id: params[:search_user] || @default_search_user)
    time_entries = time_entries.where.not(issue_id: nil)
    issue_ids = time_entries.select(:issue_id).distinct.pluck(:issue_id)
    @options_for_search_issue = Issue.where(id: issue_ids).order(updated_on: 'DESC')
      .map { |i| ["##{i.id}", i.id, {title: i.subject}] }
  end

  private
  def init_parameters
    # ユーザの選択肢と初期値
    @options_for_search_user = User.where(type: User.to_s, status: User::STATUS_ACTIVE)
      .order(login: 'ASC').map { |u| [u.login, u.id] }
    @default_search_user = User.current.id
  end
end

Redmine::Plugin.register :redmine_ddd_daily_report do
  name 'Redmine DDD Daily Report plugin'
  author '3D Incorporated'
  description 'This is a daily report plugin for Redmine'
  version '0.0.1'
  url 'http://svn/redmine/issues/30018'
  author_url 'http://www.ddd.co.jp/'

  menu :account_menu, :ddd_daily_report, { :controller => 'ddd_daily_reports', :action => 'index' }
  menu :account_menu, :ddd_timelog, { :controller => 'ddd_timelogs', :action => 'index' }
end

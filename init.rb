Redmine::Plugin.register :redmine_ddd_daily_report do
  name 'Redmine Daily Report plugin'
  author '3D Incorporated'
  description 'This is a daily report plugin for Redmine.'
  version '1.1.0'
  url 'https://github.com/ddd-redmine-plugins/redmine_daily_report'
  author_url 'http://www.ddd.co.jp/'

  menu :account_menu, :ddd_daily_report, { :controller => 'ddd_daily_reports', :action => 'index' }
  menu :account_menu, :ddd_timelog, { :controller => 'ddd_timelogs', :action => 'index' }
end

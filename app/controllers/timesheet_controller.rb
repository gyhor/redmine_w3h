class TimesheetController < ApplicationController
  unloadable

  layout 'base'
  before_filter :get_list_size
  before_filter :get_precision
  before_filter :get_activities
  before_filter :get_timesheet

  helper :sort
  include SortHelper
  helper :issues
  include ApplicationHelper
  helper :timelog

  def index
    unless @timesheet
      @timesheet ||= Timesheet.new
      @timesheet.users = [] # Clear users so they aren't selected
    end

    if @timesheet.available_projects.empty?
      render :action => 'no_projects'
      return
    end
  end

  def get_timesheet
    unless params[:timesheet]
      params[:timesheet] = {} 
      params[:timesheet][:users] = User.current.groups.length > 0 ? User.current.groups.first.users.map(&:id) : [User.current.id]
      params[:timesheet][:period_type] = Timesheet::ValidPeriodType[:free_period]
      params[:timesheet][:date_from] = 9.weekdays_ago.strftime('%Y-%m-%d')
      params[:timesheet][:date_to] = Date.today

      if params[:user_id]
        params[:timesheet][:users] = [params[:user_id]] 
      end

      if params[:deliverable_id]
        params[:timesheet][:deliverables] = [params[:deliverable_id]] 
      end
    end

    @timesheet = Timesheet.new(params[:timesheet])
  end

  def report
    if @timesheet.available_projects.empty?
      render :action => 'no_projects'
      return
    end

    respond_to do |format|
      format.html { render :action => 'report' }
    end
  end

  def delinquency
    respond_to do |format|
      format.html { render :action => 'delinquency' }
    end
  end

  def settings
    @user = User.current
    if request.post?
      @user.quota = params[:user][:quota]
      if @user.save
        flash[:notice] = l(:notice_account_updated)
      end
    end
  end

  def context_menu
    @time_entries = TimeEntry.find(:all, :conditions => ['id IN (?)', params[:ids]])
    render :layout => false
  end

  private
  def get_list_size
    @list_size = Setting.plugin_timesheet_plugin['list_size'].to_i
  end

  def get_precision
    precision = Setting.plugin_timesheet_plugin['precision']
    
    if precision.blank?
      # Set precision to a high number
      @precision = 10
    else
      @precision = precision.to_i
    end
  end

  def get_activities
    @activities = TimesheetCompatibility::Enumeration::activities
  end
end

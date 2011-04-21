class Admin::LessondescPatternsController < ApplicationController
  layout 'admin'
  before_filter :authenticate_user! #, :except => [:some_action_without_auth]
  before_filter :common_set, :only => [:new, :create, :edit, :update]

  def index
    @lessondesc_patterns = LessondescPattern.all
  end

  def show
    @lessondesc_pattern = LessondescPattern.find(params[:id])
  end

  def new
    @lessondesc_pattern = LessondescPattern.new
  end

  def create
    @lessondesc_pattern = LessondescPattern.new(params[:lessondesc_pattern])
    if @lessondesc_pattern.save
      redirect_to [:admin, @lessondesc_pattern], :notice => "Successfully created lessondesc pattern."
    else
      render :action => 'new'
    end
  end

  def edit
    @lessondesc_pattern = LessondescPattern.find(params[:id])
  end

  def update
    @lessondesc_pattern = LessondescPattern.find(params[:id])
    if @lessondesc_pattern.update_attributes(params[:lessondesc_pattern])
      redirect_to [:admin, @lessondesc_pattern], :notice  => "Successfully updated lessondesc pattern."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @lessondesc_pattern = LessondescPattern.find(params[:id])
    @lessondesc_pattern.destroy
    redirect_to admin_lessondesc_patterns_url, :notice => "Successfully destroyed lessondesc pattern."
  end

  private

  def common_set
    @languages = Language.order('code3').all
  end
end
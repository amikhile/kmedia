class Admin::LessondescPatternsController < Admin::ApplicationController
  before_filter :common_set, :only => [:new, :create, :edit, :update]
  load_and_authorize_resource

  def index
    @lessondesc_patterns = @lessondesc_patterns.order(sort_order).includes([:catalogs]).page(params[:page]).per(50)
  end

  def show
  end

  def new
  end

  def create
    @lessondesc_pattern.user = current_user
    if @lessondesc_pattern.save
      redirect_to [:admin, @lessondesc_pattern], :notice => "Successfully created Container Description pattern."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @lessondesc_pattern.update_attributes(params[:lessondesc_pattern]) &&
        @lessondesc_pattern.update_attribute(:user_id, current_user.id)
      redirect_to [:admin, @lessondesc_pattern], :notice => "Successfully updated Container Description pattern."
    else
      render :edit
    end
  end

  def destroy
    @lessondesc_pattern.destroy
    redirect_to admin_lessondesc_patterns_url, :notice => "Successfully destroyed Container Description pattern."
  end

  private

  def common_set
    @languages = Language.order('code3').all
  end

  def default_sort_column
    "pattern"
  end
end

class Admin::CatalogsController < Admin::ApplicationController
  load_resource :only => [:show, :new, :destroy, :edit, :update, :create]
  authorize_resource
  rescue_from ActiveRecord::RecordNotFound do |exception|
    redirect_to admin_lessons_path, :alert => "There is no Container with ID=#{params[:id]}."
  end

  def index
    @catalogs = Catalog.
        accessible_by(current_ability, :index).
        order(sort_order).includes(:parent)
    if params[:q]
      # request for catalogs from ui token input box
      @catalogs = get_catalogs_for_token_input
    else
      @catalogs = @catalogs.page(params[:page])
    end

    respond_to do |format|
      format.html
      format.json { render :json => @catalogs.map { |c| { :id => c.catalognodeid, :name => c.catalognodename } } }
    end
  end

  def show
    @lessons = @catalog.lessons.includes([:content_type, :language,])
  end

  def new
    @languages = Language.order('code3').all
    lang_codes = @catalog.catalog_descriptions.map(&:lang)
    @languages.each { |l|
      @catalog.catalog_descriptions.build(:lang => l.code3) unless lang_codes.include?(l.code3)
    }
    @catalog_descriptions = sort_descriptions
  end

  def create
    if @catalog.save
      redirect_to [:admin, @catalog], :notice => "Successfully created catalog."
    else
      render :action => 'new'
    end
  end

  def edit
    @languages = Language.order('code3').all
    lang_codes = @catalog.catalog_descriptions.map(&:lang)
    @languages.each { |l|
      @catalog.catalog_descriptions.build(:lang => l.code3) unless lang_codes.include?(l.code3)
    }
    @catalog_descriptions = sort_descriptions
  end

  def update
    @catalog.attributes = params[:catalog]
    update_children_visibility if visibility_changed?
    if @catalog.save
      redirect_to admin_catalog_path(@catalog), :notice => "Successfully updated catalog."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @catalog.destroy
    redirect_to admin_catalogs_url, :notice => "Successfully destroyed catalog."
  end

  def batch
    container = Lesson.find(params[:lesson_id]) rescue nil
    render :json => { ok: false, msg: "Unable to find container #{params[:lesson_id]}" } and return unless container

    case
      when md = /security_(?<security_level>[0-4])/.match(params[:batch_type])
        container.update_attribute(:secure, md[:security_level])
      else
        render :json => { ok: false, msg: "Unknown request #{params[:batch_type]}" } and return
    end
    respond_to do |format|
      format.json { render :json => { ok: true } }
    end
  end

  private
  def sort_descriptions
    catalog_descriptions_main = { }
    catalog_descriptions_all = []
    @catalog.catalog_descriptions.each { |x|
      if MAIN_LANGS.include? x.lang
        catalog_descriptions_main[x.lang] = x
      else
        catalog_descriptions_all << x
      end
    }
    MAIN_LANGS.map { |l| catalog_descriptions_main[l] } + catalog_descriptions_all.sort_by { |x| x.lang }
  end

  def default_sort_column
    "catalognodename"
  end

  def default_sort_direction
    "asc"
  end

  def update_children_visibility
  # when catalog visibility changes update visibility to it children
    children = get_all_children(@catalog).flatten
    ids = children.collect(&:catalognodeid)
    Catalog.update_all({:visible => @catalog.visible}, ["catalognodeid IN (?)", ids]) unless ids.empty?
  end

  def visibility_changed?
    @catalog.changes.has_key? ("visible")
  end

  # We use recursion method to fetch all the children for catalog node => should be changed after moving to postgres
  # Gets all children(descendants) for the given catalog node
  def get_all_children(catalog)
    all_children = []
    for child in catalog.children
      all_children << get_all_children(child)
    end

    if catalog.children.empty?
      return catalog
    else
      all_children << catalog
      return all_children
    end
  end

  # Gets catalogs for token input box
  def get_catalogs_for_token_input
    if params[:open]
      # adding an ability to filter for closed or open catalogs
      @catalogs.where("catalognodename like ? AND open = ?", "%#{params[:q]}%",params[:open].to_bool )
    else
      @catalogs.where("catalognodename like ?", "%#{params[:q]}%")
    end
  end


end

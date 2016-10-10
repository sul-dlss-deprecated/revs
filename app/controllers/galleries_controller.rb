class GalleriesController < ApplicationController

  before_filter :get_paging_params, :only=>[:index,:show]
  authorize_resource

  def index
    @filter=filter_field(params[:filter],"featured")
    @view=params[:view] || "grid"
    @per_page=(params[:per_page] || Revs::Application.config.num_default_per_page_collections).to_i # override the default for galleries
    @page_title = I18n.t('revs.nav.galleries')
    case @filter
      when 'featured'
        @galleries=Gallery.featured.page(@current_page).per(@per_page)
      when 'curator'
        @galleries=Gallery.curated.page(@current_page).per(@per_page)
      when 'user'
        @galleries=Gallery.regular_users.page(@current_page).per(@per_page)
    end
    @num_to_show_in_filmstrip=100
    respond_to do |format|
      format.html
      format.json { render :json => @galleries.to_json(:only=>[:id,:title,:gallery_type,:saved_items_count,:user_id]) }
    end
  end

  def show
    begin
      @gallery=Gallery.find(params[:id])
    rescue
      routing_error
      return
    end
    @page_title = @gallery.title
    authorize! :show, @gallery
    @view=params[:view] || "grid"
    @manage=params[:manage]
    Gallery.increment_counter(:views, @gallery.id) unless is_logged_in_user?(current_user) # your own views don't count
    @saved_items=@gallery.saved_items(current_user).page(@current_page).per(@per_page)
    respond_to do |format|
      format.html
      format.json { render :json => @gallery }
    end
  end

  def new
    @gallery=Gallery.new
    @gallery.visibility='private'
    @gallery.user_id=current_user.id
    authorize! :new, @gallery
  end

  def create
    @gallery=Gallery.create(gallery_params)
    @gallery.user_id=current_user.id
    @gallery.gallery_type=:user
    authorize! :create, @gallery
    if @gallery.save
      @message=t('revs.user_galleries.gallery_created')
      flash[:success]=@message
      redirect_to user_galleries_user_index_path(current_user.username)
    else
      render :new
    end
  end

  def edit
    @gallery=Gallery.find(params[:id])
    authorize! :edit, @gallery
  end

  def update
   @gallery=Gallery.find(params[:id])
   authorize! :update, @gallery
   @gallery.slug = nil # allow the slug to be regenerated
   @gallery.update_attributes(gallery_params)
   if @gallery.valid?
     expire_fragment('home') if @gallery.featured # if this is a featured gallery, then clear the home page cache in case the user renamed the gallery...
     @message=t('revs.user_galleries.gallery_updated')
     flash[:success]=@message
     redirect_to user_galleries_user_index_path(current_user.username)
   else
     render :edit
    end
  end

  def destroy
    @id=params[:id]
    user_id = current_user.id

    @gallery=Gallery.where(:id=>@id,:user_id=>user_id).limit(1).first
    authorize! :destroy, @gallery
    @gallery.destroy

    @message=t('revs.user_galleries.gallery_removed')

    expire_fragment('home') # in case the user deleted a featured gallery that used to be on the home page

    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to user_galleries_user_index_path(current_user.username)
                  }
      format.js { render }
    end
  end

  private

  def gallery_params
    params.require(:gallery).permit(:user_id,:title,:description,:gallery_type,:views,:visibility)
  end

end

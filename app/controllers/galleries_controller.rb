class GalleriesController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  before_filter :ajax_only, :only=>[:grid]

  def show
    get_paging_params
    @reorder=params[:reorder]
    Gallery.increment_counter(:views, @gallery.id) unless is_logged_in_user?(current_user) # your own views don't count
    @saved_item=@gallery.saved_items(current_user).page(@current_page).per(@per_page)
  end
  
  def new
    @gallery.visibility='private'
  end
  
  def create
    @gallery=Gallery.create(params[:gallery])
    @gallery.user_id=current_user.id
    @gallery.gallery_type=:user
    if @gallery.save
      @message=t('revs.user_galleries.gallery_created')
      flash[:success]=@message
      redirect_to user_galleries_path(current_user.username)
    else
      render :new
    end
  end
  
  def edit
    
  end

  def update
   @gallery.update_attributes(params[:gallery])  
   if @gallery.valid?
     @message=t('revs.user_galleries.gallery_updated')
     flash[:success]=@message
     redirect_to user_galleries_path(current_user.username)
   else
     render :edit
    end
  end
  
  def destroy
    @id=params[:id]
    user_id = current_user.id
    
    Gallery.where(:id=>@id,:user_id=>user_id).limit(1).first.destroy
    @message=t('revs.user_galleries.gallery_removed')
      
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to user_galleries_path(current_user.username)}
      format.js { render }
    end
  end
  
end

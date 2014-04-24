class GalleriesController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  def show
    get_current_page_and_order
    @gallery.update_attributes(:views=>@gallery.views+1 )    
    @saved_item=@gallery.saved_items.page(@current_page).per(@per_page)
  end
  
  def new
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
     redirect_to redirect_to user_galleries_path(current_user.username)
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

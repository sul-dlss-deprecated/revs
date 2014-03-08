class GalleriesController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  def show
    @gallery.update_attributes(:views=>@gallery.views+1 )    
  end
  
  def edit
    
  end
  
  def update
   @gallery.update_attributes(params[:gallery])  
   @message=t('revs.user_galleries.gallery_updated')
   flash[:success]=@message
   redirect_to user_galleries_path(current_user.username)
  end
  
  def destroy
    @id=params[:id]
    user_id = current_user.id
    
    Gallery.where(:id=>@id,:user_id=>user_id).limit(1).first.destroy
    @message=t('revs.user_galleries.gallery_removed')
      
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end
  end
  
end

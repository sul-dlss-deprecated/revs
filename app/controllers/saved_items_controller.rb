class SavedItemsController < ApplicationController

  authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  # if no gallery ID is passed in, assume its the default favorites list
  def create
    druid=params[:id]
    user_id=current_user.id
    gallery_id=params[:gallery_id]
    if gallery_id
      # save to specified gallery
    else
      @item=SavedItem.save_favorite(:user_id=>user_id,:druid=>druid)
      @message=t('revs.favorites.saved')
    end

    @document=SolrDocument.find(druid)
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end
    
  end

  # if no gallery ID is passed in, assume its the default favorites list
  def destroy
    druid=params[:id]
    user_id=current_user.id
    gallery_id=params[:gallery_id]
    
    @document=SolrDocument.find(druid)
    if gallery_id
      # remove from specified gallery
    else
      SavedItem.remove_favorite(:user_id=>user_id,:druid=>druid)
      @message="#{@document.title} "+t('revs.favorites.removed')
    end

    
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end

  end
  
end

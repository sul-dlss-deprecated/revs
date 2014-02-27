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
    user_id = current_user.id
    gallery_id=params[:gallery_id]
    
    @document=SolrDocument.find(druid)
    if params[:gallery_d]
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
  
  def update
    @div = "#description#{params[:id]}"
    unless params[:cancel]
      item = SavedItem.find_by_id(params[:id])
      description = params[:saved_item][:description]
      item.update_attributes({:description => description})
      @message = t('revs.favorites.item_note_updated')
      @link_text = t('revs.favorites.edit_item_note')
    end
    @favorite =  SavedItem.find_by_id(params[:id]) #refetch with new description
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to user_favorites_path(current_user.username,:page=>params[:page],:order=>params[:order])}
      format.js { render }
    end
  end
  
  def edit
    @div = "#description#{params[:id]}"
    @favorite = SavedItem.find_by_id(params[:id])
    @target = params[:id]
    respond_to do |format|
      format.html { redirect_to user_favorites_path(current_user.username, :edit_id => params[:id],:page=>params[:page],:order=>params[:order])}
      format.js { render }
    end
  end
  
end

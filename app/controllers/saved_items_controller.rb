class SavedItemsController < ApplicationController

  authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  # if no gallery ID is passed in, assume its the default favorites list
  def create
    
    saved_item=params[:saved_item]
    user_id=current_user.id
    
    if saved_item # this is a form post to add an item to a gallery
      
      gallery_id=saved_item[:gallery_id]
      druid=saved_item[:druid]
      
      if gallery_id.blank? # user is adding item to a new gallery, so create it
        gallery=Gallery.create(:user_id=>user_id,:public=>false,:gallery_type=>:user,:title=>"#{t('revs.user_galleries.singular').titlecase} #{t('revs.curator.created_on').downcase} #{show_as_date(Time.now)}")
        gallery_id=gallery.id
      end
      
      @item=SavedItem.save_to_gallery(:druid=>druid,:gallery_id=>gallery_id)
      if @item.valid?
        @message=t('revs.user_galleries.saved')
      elsif @item.errors.include?(:druid)
        @message=t('revs.user_galleries.not_saved')
      else
        @message=t('revs.error.not_saved')
      end
      @gallery_type=saved_item[:gallery_type]
    
    else # this is a post to save a favorite
    
      druid=params[:id]
      gallery_id=params[:gallery_id]
      @gallery_type=params[:gallery_type]
      @item=SavedItem.save_favorite(:user_id=>user_id,:druid=>druid)
      if @item.valid?
        @message=t('revs.favorites.saved')
      else
        @message=t('revs.error.not_saved')
      end
    
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
    if gallery_id
      SavedItem.where(:gallery_id=>gallery_id,:druid=>druid).destroy
      @message=t('revs.user_galleries.removed')
      # remove from specified gallery
    else
      SavedItem.remove_favorite(:user_id=>user_id,:druid=>druid)
      @message=t('revs.favorites.removed')
    end
    
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end

  end
  
  def update
    @div = "#description#{params[:id]}"
    item = SavedItem.find_by_id(params[:id])
    description = params[:saved_item][:description]
    item.update_attributes({:description => description})
    @message = t('revs.favorites.item_note_updated')
    @link_text = t('revs.favorites.edit_item_note')
    @favorite =  SavedItem.find_by_id(params[:id]) #refetch with new description
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to user_favorites_path(current_user.username,:page=>params[:page],:order=>params[:order])}
      format.js { render }
    end
  end
  
  def cancel
    @div = "#description#{params[:id]}"
    @favorite =  SavedItem.find_by_id(params[:id]) 
    @message=""
    @link_text=""
    respond_to do |format|
      format.html {redirect_to user_favorites_path(current_user.username,:page=>params[:page],:order=>params[:order])}
      format.js { render 'update.js' }
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

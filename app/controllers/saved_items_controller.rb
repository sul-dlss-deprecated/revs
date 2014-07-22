class SavedItemsController < ApplicationController

  before_filter :ajax_only, :only=>[:sort]
  before_filter :get_paging_params, :only=>[]

  authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  # if no gallery ID is passed in, assume its the default favorites list
  def create
    
    saved_item=params[:saved_item]
    user_id=current_user.id
    
    if saved_item # this is a form post to add an item to a gallery
      
      gallery_id=saved_item[:gallery_id]
      druid=saved_item[:druid]
      
      if gallery_id.blank? # user is adding item to a new gallery, so create it
        gallery=Gallery.create(:user_id=>user_id,:visibility=>:private,:gallery_type=>:user,:title=>"#{t('revs.user_galleries.singular').titlecase} #{t('revs.curator.created_on').downcase} #{show_as_datetime(Time.now.in_time_zone)}")
        gallery_id=gallery.id
      end
      
      @item=SavedItem.save_to_gallery(:druid=>druid,:gallery_id=>gallery_id,:user_id=>user_id)
      if @item.valid?
        @message=t('revs.user_galleries.saved')
      elsif @item.errors.include?(:druid)
        @message=t('revs.user_galleries.not_saved')
      else
        @message=t('revs.error.not_saved')
      end
      @gallery_type=saved_item[:gallery_type]

      session[:default_gallery_id]=gallery_id # store default gallery in session so it will be pre-selected the next time
    
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
      format.html { 
                    if @item.valid?
                      flash[:success]=@message
                    else
                      flash[:alert]=@message 
                    end
                    redirect_to previous_page}
      format.js { render }
    end
    
  end

  # if no gallery ID is passed in, assume its the default favorites list
  def destroy
    druid=params[:id]
    gallery_id=params[:gallery_id]
    
    @document=SolrDocument.find(druid)
    @gallery=gallery_id ? Gallery.find(gallery_id) : current_user.favorites_list
    if @gallery    
      SavedItem.where(:gallery_id=>@gallery.id,:druid=>druid).first.destroy
      @message=t('revs.favorites.removed',:list_type=>list_type_interpolator(@gallery.gallery_type))
    end

   respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to previous_page}
      format.js { render }
    end

  end
  
  def update
    @div = "#description#{params[:id]}"
    @saved_item = SavedItem.find(params[:id])
    @saved_item.description = params[:saved_item][:description]
    @saved_item.save
    @message = t('revs.favorites.item_note_updated')
    @link_text = t('revs.favorites.edit_item_note')
    respond_to do |format|
      format.html { flash[:success]=@message
                    redirect_to strip_params(previous_page,['edit_id'])}
      format.js { render }
    end
  end
  
  def sort
    SavedItem.record_timestamps=false
    @saved_item=SavedItem.find(params[:id])
    @saved_item.row_order_position=params[:position]
    @saved_item.save
    SavedItem.record_timestamps=true
    render :nothing => true
  end

  def manage
    @selected_items=params[:selected_items] || []
    @move_to_gallery=params[:move_to_gallery]
    @copy_to_gallery=params[:copy_to_gallery]
    @delete=params[:delete]
    user_id=current_user.id

    success_count=0

    @selected_items.each do |item_id|
      saved_item=SavedItem.find(item_id)
      if @move_to_gallery != "" 
        saved_item.gallery_id=@move_to_gallery
        saved_item.save
        success_count+=1 if saved_item.valid?
      elsif @copy_to_gallery != ""
        result=SavedItem.save_to_gallery(:druid=>saved_item.druid,:gallery_id=>@copy_to_gallery,:description=>saved_item.description,:user_id=>user_id)
        success_count+=1 if result.id
      elsif @delete
        saved_item.destroy
      end
    end

    if @delete
      flash[:success]=I18n.t('revs.user_galleries.items_deleted',:count=>@selected_items.size)
    else
      flash[:success]=I18n.t('revs.user_galleries.items_copied',:count=>success_count,:gallery_name=>Gallery.find(@copy_to_gallery).title) if @copy_to_gallery != ""       
      flash[:success]=I18n.t('revs.user_galleries.items_moved',:count=>success_count,:gallery_name=>Gallery.find(@move_to_gallery).title) if @move_to_gallery != ""
      flash[:success] += "  " + I18n.t('revs.user_galleries.items_duplicated') if success_count != @selected_items.size
    end
    redirect_to previous_page
  
  end

  def cancel
    @div = "#description#{params[:id]}"
    @saved_item =  SavedItem.find(params[:id]) 
    @message=""
    @link_text=""
    respond_to do |format|
      format.html {redirect_to strip_params(previous_page,['edit_id'])}
      format.js { render 'update.js' }
    end
  end
  
  def edit
    @target = params[:id]
    @div = "#description#{@target}"
    @saved_item = SavedItem.find(@target)
    respond_to do |format|
      format.html { redirect_to previous_page({:edit_id => @target}) }
      format.js { render }
    end
  end
  
end

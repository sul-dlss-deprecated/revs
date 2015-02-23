class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]
  before_filter :get_paging_params

   def index
     redirect_to flags_table_curator_tasks_path # later we can replace with a landing page
   end

   def flags

     s = params[:curator_flag_selection] || Flag.open
     @selection = s.split(',')
     
     @tab_list_flag = 'flags-by-flag' # first tab (default)
     @tab_list_item = 'flags-by-item' # second tab
     @tab_list_user = 'flags-by-user' # third tab
     @tab = params[:tab] || @tab_list_flag 
     
     @order=params[:order] || (@tab == @tab_list_user ?  "num_flags DESC" : "flags.created_at DESC") # default sort depends on tab
     
     @flag_states = Flag.groupByFlagState
     
     flags = Flag.scoped
     
     case @tab
     
       when @tab_list_flag
         flags=flags.where(['comment like ? OR items.title like ? OR flags.druid=?',"%#{@search}%","%#{@search}%",@search]) unless @search.blank?
         flags = flags.includes(:item).where(:state => @selection)
      
       when @tab_list_item
         flags=flags.where(['items.title like ? OR flags.druid=?',"%#{@search}%",@search]) unless @search.blank?
         flags=flags.select('*,COUNT("flags.druid") as num_flags,max(flags.updated_at) as updated_at').joins(:item).group("flags.druid")
       
       when @tab_list_user
         flags=flags.select('*,count(id) as num_flags,max(flags.updated_at) as updated_at').includes(:user).group("user_id")
         
     end
     
     @flags=flags.order(@order).page(@current_page).per(@per_page)
     
   end
   
   def annotations

     @tab_list_item = 'annotations-group' # first tab (default)
     @tab_list_all = 'annotations-list' # second tab 
     @tab_list_user = 'annotations-by-user' # third tab
     @tab = params[:tab] || @tab_list_item
          
     @order=params[:order] || (@tab == @tab_list_all ?  "annotations.created_at DESC" : "num_annotations DESC") # default sort depends on tab
     
     annotations=Annotation.scoped
     
      case @tab
      
        when @tab_list_item
          annotations=annotations.where(['items.title like ? OR annotations.druid=?',"%#{@search}%",@search]) unless @search.blank?
          annotations = annotations.select('annotations.druid,COUNT("annotations.druid") as num_annotations,max(annotations.updated_at) as updated_at').joins(:item).group("annotations.druid").includes(:user)
        
        when @tab_list_all
          annotations=annotations.includes(:item)
          annotations=annotations.where(['items.title like ? OR annotations.druid=?',"%#{@search}%",@search]).includes(:item) unless @search.blank?
        
        when @tab_list_user
          annotations=annotations.select('*,count(id) as num_annotations,max(annotations.updated_at) as updated_at').includes(:user).group("user_id")
      end
 
      @annotations=annotations.order(@order).page(@current_page).per(@per_page)               

   end
   
   def edits
     
     @tab_list_item = 'edits-by-item' # first tab (default)
     @tab_list_user = 'edits-by-user'  # second tab
     @tab = params[:tab] || @tab_list_item
     
     @order=params[:order] || "num_edits DESC"

     edits=ChangeLog.scoped
     
     case @tab
       
       when @tab_list_item
         edits=edits.select("count(id) as num_edits,druid").where(:operation=>'metadata update').group('druid')
       when @tab_list_user
         edits=edits.select("count(id) as num_edits,user_id").where(:operation=>'metadata update').includes(:user).group('user_id')
       
     end
     
     @edits=edits.order(@order).page(@current_page).per(@per_page)  

   end
   
   def favorites

     @tab_list_item = 'favorites-by-item' # first tab (default)
     @tab_list_user = 'favorites-by-user' # second tab
     @tab = params[:tab] || @tab_list_item
     
     @order=params[:order] || (@tab == @tab_list_item ?  "num_favorites DESC" : "num_galleries DESC") # default sort depends on tab
     
     saved_items=SavedItem.scoped     
     
      case @tab
        
        when @tab_list_item
          saved_items=saved_items.where(['items.title like ? OR saved_items.druid=?',"%#{@search}%",@search]) unless @search.blank?
          saved_items=saved_items.select("count(saved_items.id) as num_favorites,saved_items.druid,max(saved_items.updated_at) as updated_at").joins(:gallery,:item).group('saved_items.druid')
        
        when @tab_list_user
          saved_items=Gallery.select("count(id) as num_galleries,sum(saved_items_count) as saved_items_count,user_id,max(galleries.updated_at) as updated_at").includes(:user,:all_saved_items).where('galleries.saved_items_count > 0').group('user_id')
        
      end
         
      @saved_items=saved_items.order(@order).page(@current_page).per(@per_page)

   end

   def galleries
     
      @filter=params[:filter] || 'all'
      @visibility_options={'All galleries'=>'all','Public only'=>'public','Curator only'=>'curator'}
      
      all_visibilities=['public','curator'] 
      if can?(:administer, :all)  # admins can even see private galleries of any user
        @visibility_options.merge!({'Private only'=>'private'}) 
        all_visibilities << 'private' 
      end 

      galleries=Gallery.where(:gallery_type=>'user')
      galleries= (@filter == 'all' ? galleries.where(['visibility in (?) OR user_id = ?',all_visibilities,current_user.id]) :  galleries.where(:visibility=>@filter))
      
      @galleries=galleries.order(@order).page(@current_page).per(@per_page)

   end
      
   # an ajax call to set the curator edit mode
   def set_edit_mode
     @document=SolrDocument.find(params[:id])
     @value=params[:value]
     session[:curator_edit_mode]=@value
     flash[:notice] = t('revs.messages.changes_not_saved',:rails_env=>Rails.env) if (@value && ['staging'].include?(Rails.env))
   end

   # an ajax call to set the item visibility
   def set_visibility
     @document=SolrDocument.find(params[:id])
     @value=params[:value].to_sym
     @document.visibility=@value
     @document.save
     flash[:success] = (@value == :hidden ? t('revs.messages.hide_image_success') : t('revs.messages.show_image_success'))
   end
   
   # an ajax call for user submitted in-place edit
   def edit_metadata
      @document=SolrDocument.find(params[:id])
      updates=params[:document]
      updates.each {|field,value| @document.send("#{field}=",value)}
      if @document.save(:user=>current_user)
        flash[:success] = t('revs.messages.saved')
      else  
        @message = "#{@document.errors.join('. ')}."
      end
   end

   # an ajax call to set the item to be the top priority item for collection
   def set_top_priority_item
     @document=SolrDocument.find(params[:id])
     @document.set_top_priority
     flash[:success] = t('revs.messages.set_top_priority')
   end

end

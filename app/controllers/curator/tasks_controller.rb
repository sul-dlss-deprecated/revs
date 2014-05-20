class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]
  before_filter :get_paging_params

   def index
     redirect_to flags_table_curator_tasks_path # later we can replace with a landing page
   end

   def flags
     s = params[:selection] || Flag.open
     
     @selection = s.split(',')
     @order=params[:order] || "created_at DESC"
     @order_all=params[:order_all] || "created_at DESC"
     @order_user = params[:order_user] || "num_flags DESC"
     
     @flag_states = Flag.groupByFlagState
     @flags = Kaminari.paginate_array(Flag.where(:state => @selection).order(@order)).page(params[:pagina]).per(@per_page)
     @flags_grouped=Flag.select('*,COUNT("druid") as num_flags,max(flags.updated_at) as updated_at').group("druid").order(@order_all).page(params[:pagina2]).per(@per_page)
     @flags_by_user=Flag.select('*,count(id) as num_flags,max(flags.updated_at) as updated_at').includes(:user).group("user_id").order(@order_user).page(params[:pagina3]).per(@per_page)

     @tab_list_item = 'flags-by-item'
     @tab_list_user = 'flags-by-user'
     @tab_list_flag = 'flags-by-flag'
     @tab = params[:tab] || @tab_list_flag
   end
   
   def annotations
     @order_by_item = params[:order_by_item] || "num_annotations DESC"
     @order_all = params[:order_all] || "created_at DESC"
     @order_user = params[:order_user] || "num_annotations DESC"
     
     @annotations_by_item = Annotation.select('druid,COUNT("druid") as num_annotations,max(annotations.updated_at) as updated_at').group("druid").order(@order_by_item).includes(:user).page(params[:pagina]).per(@per_page)
     @annotations_list = Annotation.order(@order_all).page(params[:pagina2]).per(@per_page)
     @annotations_by_user=Annotation.select('*,count(id) as num_annotations,max(annotations.updated_at) as updated_at').includes(:user).group("user_id").order(@order_user).page(params[:pagina3]).per(@per_page)
     
     @tab_group = 'annotations-group'
     @tab_list_all = 'annotations-list'
     @tab_list_user = 'annotations-by-user'
     @tab = params[:tab] || @tab_list_item
   end
   
   def edits
     @order = params[:order] || "num_edits DESC"
     @order_user = params[:order_user] || "num_edits DESC"
     
     @edits_by_item=ChangeLog.select("count(id) as num_edits,druid").where(:operation=>'metadata update').group('druid').order(@order).page(params[:pagina]).per(@per_page)
     @edits_by_user=ChangeLog.select("count(id) as num_edits,user_id").where(:operation=>'metadata update').includes(:user).group('user_id').order(@order_user).page(params[:pagina2]).per(@per_page)

     @tab_list_item = 'edits-by-item'
     @tab_list_user = 'edits-by-user'
     @tab = params[:tab] || @tab_list_item
   end
   
   def favorites
      @order = params[:order] || "num_favorites DESC"
      @order_user = params[:order_user] || "num_galleries DESC"

      @saved_items_by_item=SavedItem.select("count(id) as num_favorites,druid,max(saved_items.updated_at) as updated_at").includes(:gallery).group('druid').order(@order).page(params[:pagina]).per(@per_page)
      @saved_items_by_user=Gallery.select("count(id) as num_galleries,user_id,max(galleries.updated_at) as updated_at").includes(:user,:all_saved_items).group('user_id').order(@order_user).page(params[:pagina2]).per(@per_page)

      @tab_list_item = 'favorites-by-item'
      @tab_list_user = 'favorites-by-user'
      @tab = params[:tab] || @tab_list_item
   end

   def galleries
      @filter=params[:filter] || 'all'
      @visibility_options={'All galleries'=>'all','Public only'=>'public','Curator only'=>'curator'}
      
      all_visibilities=['public','curator'] 
      if can?(:administer, :all)  # admins can even see private galleries of any user
        @visibility_options.merge!({'Private only'=>'private'}) 
        all_visibilities << 'private' 
      end 

      @galleries=Gallery.where(:gallery_type=>'user')
      if @filter == 'all'
        @galleries=@galleries.where(['visibility in (?) OR user_id = ?',all_visibilities,current_user.id])
      else
        @galleries=@galleries.where(:visibility=>@filter)
      end
      @galleries=@galleries.order(@order).page(@current_page).per(@per_page)

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

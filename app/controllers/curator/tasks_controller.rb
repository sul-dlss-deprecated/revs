class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]

   def index
     redirect_to flags_table_curator_tasks_path # later we can replace with a landing page
   end

    # get all flags grouped by druid with counts
   def flags
     s = params[:selection] || Flag.open
     
     @selection = s.split(',')
     @order=params[:order] || 'num_flags DESC'
     @order_all=params[:order_all] || "created_at DESC"
     @order_user = params[:order_user] || "flags.updated_at DESC"
     
     @flags_grouped=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:pagina2]).per(Flag.per_table_page)
     @flag_states = Flag.groupByFlagState
     #@flags_grouped = Kaminari.paginate_array(Flag.all).page(params[:pagina2]).per(Flag.per_table_page)
     @flags = Kaminari.paginate_array(Flag.where(:state => @selection).order(@order_all)).page(params[:pagina]).per(Flag.per_table_page)
     @flags_by_user=Flag.select('*,count(id) as num_flags').includes(:user).group("user_id").order(@order_user).page(params[:pagina3]).per(Flag.per_table_page)

     @tab_list_item = 'flags-by-item'
     @tab_list_user = 'flags-by-user'
     @tab_list_flag = 'flags-by-flag'
     @tab = params[:tab] || @tab_list_item
   end
   
   def annotations
     @order = params[:order] || "created_at DESC"
     @order_all = params[:order_all] || "created_at DESC"
     @order_user = params[:order_user] || "annotations.updated_at DESC"
     
     #@annotations = Kaminari.paginate_array(Annotation.order(@order).all).page(params[:page]).per(Annotation.per_table_page)
     @annotations = Annotation.select('*,COUNT("druid") as num_annotations').group("druid").order(@order).includes(:user).page(params[:pagina2]).per(Annotation.per_table_page)
     @annotations_list = Kaminari.paginate_array(Annotation.order(@order_all).all).page(params[:pagina]).per(Annotation.per_table_page)
     @annotations_by_user=Annotation.select('*,count(id) as num_annotations').includes(:user).group("user_id").order(@order_user).page(params[:pagina3]).per(Annotation.per_table_page)
     
     @tab_group = 'annotations-group'
     @tab_list_all = 'annotations-list'
     @tab_list_user = 'annotations-by-user'
     @tab = params[:tab] || @tab_group
   end
   
   def edits
     @order = params[:order] || "num_edits DESC"
     @order_user = params[:order_user] || "num_edits DESC"
     
     @edits_by_item=ChangeLog.select("count(id) as num_edits,druid,updated_at").where(:operation=>'metadata update').group('druid').order(@order).page(params[:pagina])
     @edits_by_user=ChangeLog.select("count(id) as num_edits,user_id,updated_at").where(:operation=>'metadata update').includes(:user).group('user_id').order(@order_user).page(params[:pagina2])

     @tab_list_item = 'edits-by-item'
     @tab_list_user = 'edits-by-user'
     @tab = params[:tab] || @tab_list_item
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

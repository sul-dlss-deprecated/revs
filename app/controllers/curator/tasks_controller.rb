class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]

    # get all flags grouped by druid with counts
   def index
     s = params[:selection] || Flag.open
     @selection = s.split(',')
     @order=params[:order] || 'num_flags DESC'
     @order_all=params[:order_all] || "druid"
     @flags_grouped=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:pagina2]).per(Flag.per_table_page)
     @flag_states = Flag.groupByFlagState
     @tab = params[:tab]
     #@flags_grouped = Kaminari.paginate_array(Flag.all).page(params[:pagina2]).per(Flag.per_table_page)
     @flags = Kaminari.paginate_array(Flag.where(:state => @selection).order(@order_all)).page(params[:pagina]).per(Flag.per_table_page)
   end
   
   def annotations
     @order = params[:order] || "druid"
     @order_all = params[:order2] || "druid"
     #@annotations = Kaminari.paginate_array(Annotation.order(@order).all).page(params[:page]).per(Annotation.per_table_page)
     @annotations = Annotation.select('*,COUNT("druid") as num_annotations').group("druid").order(@order).page(params[:pagina2]).per(Annotation.per_table_page)
     @annotations_list = Kaminari.paginate_array(Annotation.order(@order2).all).page(params[:pagina]).per(Annotation.per_table_page)
     
     @tab_group = 'annotations-group'
     @tab_list_all = 'annotations-list'
     @tab = params[:tab] || @tab_group
   end
   
   def edits
     @order = params[:order] || "num_edits DESC"
     @order2 = params[:order2] || "num_edits DESC"
     @edits_by_item=ChangeLog.select("count(id) as num_edits,druid,updated_at").where(:operation=>'metadata update').group('druid').order(@order).page(params[:pagina])
     @edits_by_user=ChangeLog.select("count(id) as num_edits,user_id,updated_at").where(:operation=>'metadata update').includes(:user).group('user_id').order(@order2).page(params[:pagina2])

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
      if @document.save(current_user)
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

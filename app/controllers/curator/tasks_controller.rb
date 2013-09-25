class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]

    # get all flags grouped by druid with counts
   def index
     @order=params[:order] || 'num_flags DESC'
     @flags_grouped=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:pagina2]).per(Flag.per_table_page)
     @flag_states = Flag.groupByFlagState
     #@flags_grouped = Kaminari.paginate_array(Flag.all).page(params[:pagina2]).per(Flag.per_table_page)
     @flags = Kaminari.paginate_array(Flag.where(:state => Flag.open)).page(params[:pagina]).per(Flag.per_table_page)
   end
   
   # an ajax call to set the curator edit mode
   def set_edit_mode
     session[:curator_edit_mode]=params[:value]
     @document=SolrDocument.find(params[:id])
   end

   # an ajax call for user submitted in-place edit
   def edit_metadata
      @document=SolrDocument.find(params[:id])
      updates=params[:document]
      updates.each {|field,value| @document.send("#{field}=",value)}
      if @document.save(current_user)
        flash[:success] = t('revs.messages.saved')
      else  
        @message = "#{@document.errors.join(', ')}."
      end
   end

   # an ajax call to set the item to be the top priority item for collection
   def set_top_priority_item
     @document=SolrDocument.find(params[:id])
     @document.set_top_priority
     flash[:success] = t('revs.messages.set_top_priority')
   end

end

class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata,:set_top_priority_item]

    # get all flags grouped by druid with counts
   def index
     @order=params[:order] || 'num_flags DESC'
     @flags=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:page])
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
      if @document.save
        flash[:success] = "#{t('revs.messages.saved')}."        
      else  
        @message = "#{@document.errors.join(', ')}."
      end
   end

   # an ajax call to set the item to be the top priority item for collection
   def set_top_priority_item
     @document=SolrDocument.find(params[:id])
     @document.set_top_priority
     if @document.save
       flash[:success] = "Successfully set this image to represent its collection."
     else
       @message = "#{@document.errors.join(', ')}."
     end
   end

end

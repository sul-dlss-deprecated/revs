class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in
  before_filter :ajax_only, :only=>[:set_edit_mode,:edit_metadata]

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

   # TODO show validation errors
   # an ajax call for user submitted an in-place edit
   def edit_metadata
      @document=SolrDocument.find(params[:id])
      updates=params[:solr_document]
      updates.each {|field,value| @document.send("#{field}=",value)}
      @document.save
      head :ok
   end
   
end

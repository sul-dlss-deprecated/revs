class Curator::TasksController < ApplicationController

  before_filter :check_for_curator_logged_in

    # get all flags grouped by druid with counts
   def index
     @order=params[:order] || 'num_flags DESC'
     @flags=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:page])
   end
   
   # an ajax call to set the curator edit mode
   def set_edit_mode
     return unless (request.xhr? && can?(:update_metadata, :all))
     session[:curator_edit_mode]=params[:value]
     render :nothing=>true
   end
   
end

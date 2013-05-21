class Curator::TasksController < Curator::CuratorController

    # get all flags grouped by druid with counts
   def index
     @order=params[:order] || 'num_flags DESC'
     @flags=Flag.select('*,COUNT("druid") as num_flags').group("druid").order(@order).page(params[:page])
   end
   
end

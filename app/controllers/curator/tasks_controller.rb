class Curator::TasksController < Curator::CuratorController

    # get all flags
   def index
     @flags=Flag.order('created at DESC').page params[:page]
   end
   
end

class GalleriesController < ApplicationController

  load_and_authorize_resource  # ensures only people who have access via cancan (defined in ability.rb) can do this

  def show
    @gallery.update_attributes(:views=>@gallery.views+1 )    
  end
  
end

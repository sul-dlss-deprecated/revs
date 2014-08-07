class Admin::GalleryHighlightsController < AdminController

  before_filter :ajax_only, :only=>[:set_highlight,:sort]
  
  def index
    @galleries=Gallery.public_galleries.rank(:row_order)
  end

  # an ajax call to set which galleries are highlighted
  def set_highlight
    Gallery.find(params[:id]).update_column(:featured,params[:highlighted] == 'true')
    expire_fragment('home')
    render :nothing=>true
  end
  
  def sort
    Gallery.record_timestamps=false
    @gallery=Gallery.find(params[:id])
    @gallery.row_order_position=params[:position]
    @gallery.save
    Gallery.record_timestamps=true
    expire_fragment('home')
    render :nothing => true
  end
    
end

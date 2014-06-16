class Admin::GalleryHighlightsController < AdminController

  before_filter :ajax_only, :only=>[:set_highlight,:sort]
  
  def index
    # get all public galleries
    @galleries=Gallery.where(:visibility=>'public',:gallery_type=>'user').order('position ASC,created_at DESC')
  end

  # an ajax call to set which galleries are highlighted
  def set_highlight
    Gallery.find(params[:id]).update_column(:featured,params[:highlighted] == 'true')
    render :nothing=>true
  end
  
  def sort
    Gallery.record_timestamps=false
    @gallery=Gallery.find(params[:id])
    @gallery.position=params[:position]
    @gallery.save
    Gallery.record_timestamps=true
    render :nothing => true
  end
    
end

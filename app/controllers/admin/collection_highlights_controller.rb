class Admin::CollectionHighlightsController < AdminController

  before_filter :ajax_only, :only=>[:set_highlight]
  
  def index
    @collections=SolrDocument.all_collections(:sort=>'highlighted_ssi desc, highlighted_dti desc')
  end
  
  def set_highlight
    @collection=SolrDocument.find(params[:id])
    @collection.update_solr('highlighted_ssi','update',params[:highlighted])
    @collection.update_solr('highlighted_dti','update',show_as_timestamp(Time.now()))
    expire_fragment('home')
    render :nothing=>true
  end
  
end

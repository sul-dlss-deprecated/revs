class Admin::CollectionHighlightsController < ApplicationController

  before_filter :check_for_admin_logged_in
  before_filter :ajax_only, :only=>[:set_highlight]
  before_filter :set_no_cache
  
  def index
    @collections=SolrDocument.all_collections
  end
  
  def edit
    @id=params[:id]
    @collection=SolrDocument.find(params[:id])
  end
  
  def update
    @collection=SolrDocument.find(params[:id])
    @collection.update_solr('highlighted_ssi','update',params[:highlighted])
    flash[:success]=t('revs.messages.saved')
    redirect_to admin_collection_highlights_path
  end
  
  def set_highlight
    @collection=SolrDocument.find(params[:id])
    @collection.update_solr('highlighted_ssi','update',params[:highlighted])
    puts params[:id] + " " + params[:highlighted]
    render :nothing=>true
  end
  
end

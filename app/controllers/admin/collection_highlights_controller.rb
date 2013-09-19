class Admin::CollectionHighlightsController < ApplicationController

  before_filter :check_for_admin_logged_in
  
  def index
    @collections=SolrDocument.all_collections
    @collection_highlights=CollectionHighlight.all_in_solr
  end
  
end

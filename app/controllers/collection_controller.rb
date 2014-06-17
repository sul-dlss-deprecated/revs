class CollectionController < ApplicationController

  before_filter :authorize
  
  def index
    @view=params[:view] || 'grid'
    @collections=SolrDocument.all_collections
  end

  protected
  def authorize
    not_authorized unless can? :read,:collections_page
  end
  
end

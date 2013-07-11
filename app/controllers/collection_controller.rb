class CollectionController < ApplicationController

  def index
    @collections=SolrDocument.all_collections
  end

end

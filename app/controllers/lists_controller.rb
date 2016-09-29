class ListsController < ApplicationController

  before_filter :get_paging_params

  def index
    @saved_queries = SavedQuery.where(:active=>true).rank(:row_order).page(@current_page).per(@per_page)
  end
  
end
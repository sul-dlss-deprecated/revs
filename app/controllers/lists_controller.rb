class ListsController < ApplicationController

  before_filter :get_paging_params
  before_filter { unauthorized! if cannot? :read, :lists }

  def index
    @saved_queries = can?(:curate, :all) ? SavedQuery.all_lists : SavedQuery.public_lists  # if you aren't a curator or admin, you only see the public ones
    @saved_queries = @saved_queries.rank(:row_order).page(@current_page).per(@per_page)
    redirect_to root_path if @saved_queries.size == 0
  end

end

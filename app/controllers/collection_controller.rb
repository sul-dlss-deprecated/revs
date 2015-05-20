class CollectionController < ApplicationController

  before_filter :authorize
  
  def index
  	get_paging_params
    @page_title = I18n.t('revs.nav.collections')
    @per_page = Revs::Application.config.num_default_per_page_collections # override the default for collections
    @view=params[:view] || 'grid'
    @archive=params[:archive] || ''
	  @collections=Kaminari.paginate_array(SolrDocument.all_collections(:archive=>@archive)).page(@current_page).per(@per_page)
    @num_to_show_in_filmstrip=100
  end

  protected
  def authorize
    not_authorized unless can? :read,:collections_page
  end
  
end

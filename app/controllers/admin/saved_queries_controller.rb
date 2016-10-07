class Admin::SavedQueriesController < AdminController

  before_filter :ajax_only, :only=>[:sort]
  load_and_authorize_resource 
  skip_load_resource :only => :create

  def index
    @saved_queries = SavedQuery.all.rank(:row_order)
  end

  def new
    @saved_query=SavedQuery.new
    @saved_query.query=params[:query]
    @saved_query.thumbnail=params[:thumbnail]
    @saved_query.active=true
    @saved_query.visibility='public'
    @saved_query.user_id=current_user.id
  end

  def create
    @saved_query=SavedQuery.create(saved_query_params)
    @saved_query.user_id=current_user.id
    if @saved_query.save
      @message=t('revs.messages.created')
      flash[:success]=@message
      redirect_to admin_saved_queries_path
    else
      render :new
    end
  end
  
  def edit

  end

  def show
    redirect_to @saved_query.url
  end

  def update
    @saved_query.slug = nil # allow the slug to be regenerated
    if @saved_query.update_attributes(saved_query_params)
     flash[:success]=t('revs.messages.saved')
     redirect_to admin_saved_queries_path
    else
      render :edit
    end
  end
  
  def destroy
    @saved_query.destroy
    respond_to do |format|
      format.js   { render }
      format.html { redirect_to admin_saved_queries_path }
    end
  end

  def sort
    SavedQuery.record_timestamps=false
    @saved_query=SavedQuery.find(params[:id])
    @saved_query.row_order_position=params[:position]
    @saved_query.save
    SavedQuery.record_timestamps=true
    render :nothing => true
  end
  
  private
  def saved_query_params
    params.require(:saved_query).permit(:title,:query,:visibility,:active,:thumbnail,:description)
  end
  
end

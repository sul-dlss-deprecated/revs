class Admin::SavedQueriesController < AdminController

  def index
    @saved_queries = SavedQuery.all.rank(:row_order)
  end

  def new
    @saved_query=SavedQuery.new
    @saved_query.active=true
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
    @saved_query=SavedQuery.find(params[:id])
  end

  def show
    redirect_to :action=>:index
  end

  def update
    @saved_query=SavedQuery.find(params[:id])
    @saved_query.slug = nil # allow the slug to be regenerated
    if @saved_query.update_attributes(saved_query_params)
     flash[:success]=t('revs.messages.saved')
     redirect_to admin_saved_queries_path
    else
      render :edit
    end
  end
  
  def destroy
    @id=params[:id]
    @saved_query=SavedQuery.find(@id).destroy
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

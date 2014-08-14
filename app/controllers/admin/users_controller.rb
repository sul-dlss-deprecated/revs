class Admin::UsersController < AdminController 

  def index
    get_paging_params
    @search=params[:search]
    @role = params[:role] || 'curator'
    @filter = params[:filter] || 'all'
    @filter_role = params[:filter_role] || 'all'
    @filter_visibility = params[:filter_visibility] || 'all'

    @users = User.scoped
    
    if !@search.blank?
      @users=@users.where(['email like ? OR username like ? OR first_name like ? OR last_name like ?',"%#{@search}%","%#{@search}%","%#{@search}%","%#{@search}%"])
    end
    
    if @filter == 'stanford'
      @users=@users.where("sunet != '' AND sunet is not null")    
    elsif @filter == 'non-stanford'
      @users=@users.where("sunet = '' OR sunet is null")
    end

    if @filter_role != 'all'
      @users=@users.where(['role = ?',@filter_role])
    end

    if @filter_visibility == 'public'
      @users=@users.where(:public => true)
    elsif @filter_visibility == 'private'
      @users=@users.where(:public => false)
    end

    @users=@users.order(@order).page(@current_page).per(@per_page)

  end

  def edit
    @user=User.find(params[:id])
  end
  
  def show
    redirect_to :action=>:index
  end
    
  def update
    if params[:user][:password].blank? # if the admin user didn't enter a new password, remove them from the hash so they don't try to get updated
      params[:user].delete(:password) 
      params[:user].delete(:password_confirmation)
    end
    @user=User.find(params[:id])
    if @user.update_attributes(params[:user]) 
     @user.update_lock_status(params[:lock])
     flash[:success]=t('revs.messages.saved')
     redirect_to admin_users_path
    else
      render :edit
    end
  end

  def bulk_update_role
    get_paging_params
    @role=params[:role]
    @selected_users=params[:selected_users]
    if @selected_users
      @selected_users.each {|user_id| User.find(user_id).update_attributes(:role=>@role)}
      flash[:success]=t('revs.admin.user_roles_updated',:num=>@selected_users.size,:role=>@role)
    else
      flash[:error]=t('revs.admin.no_user_roles_updated')
    end
    redirect_to admin_users_path(paging_params({:email=>params[:email],:role=>@role}))
  end
  
  def destroy
    @user=User.find(params[:id]).destroy
  end

end

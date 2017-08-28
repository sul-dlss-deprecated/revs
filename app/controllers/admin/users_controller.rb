class Admin::UsersController < AdminController

  def index
    get_paging_params
    @status = params[:status] || 'true'
    @filter = filter_field(params[:filter])
    @filter_role = params[:filter_role] || "all"
    @filter_visibility = filter_field(params[:filter_visibility])
    @filter_status = params[:filter_status] || "all"
    @users = User.all

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

    if @filter_status == 'active'
      @users=@users.where(:active => true)
    elsif @filter_status == 'inactive'
      @users=@users.where(:active => false)
    elsif @filter_status == 'inactive_new'
      @users=@users.where(:active => false, :login_count => 0)
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
    if @user.update_attributes(user_params)
     @user.update_lock_status(params[:lock])
     flash[:success]=t('revs.messages.saved')
     redirect_to admin_users_path
    else
      render :edit
    end
  end

  def bulk_update_status
    get_paging_params
    @status=params[:status]
    @selected_users=params[:selected_users]
    if @selected_users
      @selected_users.each do |user_id|
          user=User.find(user_id)
          user.active=@status
          user.save
       end
      flash[:success]=t('revs.admin.user_status_updated',:num=>@selected_users.size,:status=>@status)
    else
      flash[:error]=t('revs.admin.no_users_updated')
    end
    redirect_to admin_users_path(paging_params({:email=>params[:email],:status=>@status}))
  end

  def destroy
    @user=User.find(params[:id]).destroy
  end

  private
  def user_params
    params.require(:user).permit(:username, :email, :sunet, :password, :password_confirmation, :remember_me,
                  :role, :bio, :first_name, :last_name, :public, :url, :twitter, :login,
                  :subscribe_to_mailing_list, :subscribe_to_revs_mailing_list, :active,
                  :avatar, :avatar_cache, :remove_avatar, :login_count, :favorites_public)
  end
end

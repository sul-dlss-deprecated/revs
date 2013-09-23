class Admin::UsersController < ApplicationController 

  before_filter :check_for_admin_logged_in

  def index
    @email=params[:email]
    @order=params[:order] || 'email'
    users_per_page = 10
    
    if !@email.blank?
      @users=User.where(['email like ?',"#{@email}%"]).order(@order).page(param[:page]).per(users_per_page)
    else
      @users=User.order(@order).page(params[:page]).per(users_per_page)
    end
  end

  def edit
    @user=User.find(params[:id])
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

  def destroy
    @user=User.find(params[:id]).destroy
  end

end

class Admin::UsersController < Admin::AdminController

  def index
    @email=params[:email]
    @order=params[:order] || 'email'
    
    if !@email.blank?
      @users=User.where(['email like ?',"#{@email}%"]).page
    else
      @users=User.order(@order).page params[:page]
    end
  end

  def edit
    @user=User.find(params[:id])
  end
    
  def update
    @user=User.find(params[:id])
    if @user.update_attributes(params[:user]) 
     flash[:success]="User updated."
     redirect_to admin_users_path
    else
      render :edit
    end
  end

  def destroy
    @user=User.find(params[:id]).destroy
  end

end

# this overrides the Devise Session Controller, so we can do some specific things as login time
class SessionsController < Devise::SessionsController
  
  def create
    user=User.where(:email=>params[:user][:email])
    if user.size == 1 && user.first.sunet_user?
      sign_out
      redirect_to :root, :alert=>'Stanford users must use webauth via SunetID to access their accounts.'
      return false
    else
      super
    end
  end
  
end

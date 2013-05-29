# this overrides the Devise Session Controller, so we can do some specific things as login time
class SessionsController < Devise::SessionsController
  
  def new
    store_referred_page
    super
  end
  
  def create
    user=User.where('email=? or username=?',params[:user][:login],params[:user][:login])
    if user.size == 1 && user.first.sunet_user?
      sign_out
      redirect_to :root, :alert=>'Stanford users must use webauth via SunetID to access their accounts.'
      return false
    else
      super
    end
  end
  
end

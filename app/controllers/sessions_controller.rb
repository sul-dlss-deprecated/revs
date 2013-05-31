# this overrides the Devise Session Controller, so we can do some specific things at login time
class SessionsController < Devise::SessionsController
  
  # sign in form
  def new
    store_referred_page
    super
  end
  
  # sign in form submit method
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

  def webauth_login
    if Revs::Application.config.simulate_sunet_user && Rails.env != 'production' # if we are simulating sunet logins and we are not in production, set a fake webauth cookie manually for testing
      session["WEBAUTH_USER"]=Revs::Application.config.simulate_sunet_user
    end
    redirect_to params[:referrer] || root_url
  end

  def webauth_logout
    if Revs::Application.config.simulate_sunet_user && Rails.env != 'production' # if we are simulating sunet logins and we are not in production, kill the fake webauth cookie manually for testing
     session["WEBAUTH_USER"]=nil
    end
    sign_out
    flash[:notice] = "You have successfully logged out of WebAuth." unless request.env["WEBAUTH_USER"]
    redirect_to root_url
  end
    
end

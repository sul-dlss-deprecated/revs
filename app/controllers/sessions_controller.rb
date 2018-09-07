# this overrides the Devise Session Controller, so we can do some specific things at login time
class SessionsController < Devise::SessionsController

  # sign in form
  def new
    return if redirect_home_if_signed_in
    store_referred_page
    super
  end

  # sign in form submit method
  def create
    user=User.where('email=? or username=?',params[:user][:login],params[:user][:login])
    if user.size == 1 && user.first.sunet_user? # sunet users should not be able to log in this way -- boot them over to the home page with a webauth message
      sign_out
      redirect_to :root, :alert=>t('revs.authentication.stanford_webauth')
      return false
    else
      super
    end
  end

  def destroy
    session[:curator_edit_mode] = nil
    super
  end

  def webauth_login
    if Revs::Application.config.simulate_sunet_user && Rails.env != 'production' # if we are simulating sunet logins and we are not in production, set a fake webauth cookie manually for testing
      session["REMOTE_USER"]=Revs::Application.config.simulate_sunet_user
    end
    redirect_to params[:referrer] || root_url
  end

  def webauth_logout
    if Revs::Application.config.simulate_sunet_user && Rails.env != 'production' # if we are simulating sunet logins and we are not in production, kill the fake webauth cookie manually for testing
     session["REMOTE_USER"]=nil
    end
    sign_out
    flash[:notice] = t('revs.authentication.stanford_webauth_logout') unless request.env["REMOTE_USER"]
    redirect_to '/Shibboleth.sso/Logout'
  end

end

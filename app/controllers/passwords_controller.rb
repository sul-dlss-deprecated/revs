# this overrides the Devise Passwords Controller, so we can do some specific things at password reset time
class PasswordsController < Devise::PasswordsController
  
  # don't let stanford users reset their password
  def create
    user=User.find_by_email(params[:user][:login])
    if user && user.sunet_user?
      redirect_to :root, :alert=>t('revs.authentication.stanford_warning')
      return false
    else
      super  
    end
  end
  
end
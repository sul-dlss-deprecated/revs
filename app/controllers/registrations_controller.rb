# this overrides the Devise Registrations Controller, so we can do some specific things as registration time
class RegistrationsController < Devise::RegistrationsController

  def new
    store_referred_page
    super
  end
    
  def create
    if params[:user][:email].include?("@stanford.edu") # anyone who tries to register with a stanford email address will get an error
      redirect_to :root, :alert=>'Stanford users should not create a new account.  Use webauth via SunetID to access your account.'
      return false
    else
      super
    end
  end
  
  # ajax call to check usernames
  def check_username
    return unless request.xhr?
    @user=User.where('username=?',params[:username])    
  end
  
  # ajax call to check emails
  def check_email
    return unless request.xhr?
    @user=User.where('email=?',params[:email])    
  end
    
end

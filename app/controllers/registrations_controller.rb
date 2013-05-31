# this overrides the Devise Registrations Controller, so we can do some specific things as registration time
class RegistrationsController < Devise::RegistrationsController

  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy, :edit_account, :update_account]
  before_filter :no_sunet_users, :only=>[ :edit_account, :update_account]
  
  # sign up form
  def new
    store_referred_page
    super
  end
    
  # sign up form submit method  
  def create
    if params[:user][:email].include?("@stanford.edu") # anyone who tries to register with a stanford email address will get an error
      redirect_to :root, :alert=>'Stanford users should not create a new account.  Use webauth via SunetID to access your account.'
      return false
    else
      super
    end
  end

  def update
    
    @user = User.find(current_user.id)

    params[:user].delete(:current_password)  # these aren't on the form, but let's remove them anyway to prevent hacking attempt
    params[:user].delete(:email)

    successfully_updated = @user.update_without_password(params[:user])

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to user_profile_name_path(@user.username)
    else
      render "edit"
    end

  end    
  
  # logged in user edit password form
  def edit_account
    @user = User.find(current_user.id)
  end

  # logged in user edit password submit method
  def update_account

    @user = User.find(current_user.id)

    successfully_updated = @user.update_with_password(params[:user])

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to user_profile_name_path(@user.username)
    else
      render "edit_account"
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

  private

  # check if we need password to update user data
  # ie if password or email was changed
  # extend this as needed
  def needs_password?(user, params)
    user.email != params[:user][:email] || !params[:user][:password].blank?
  end
      
end

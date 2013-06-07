# this overrides the Devise Registrations Controller, so we can do some specific things as registration time
class RegistrationsController < Devise::RegistrationsController

  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy, :edit_account, :update_account]
  before_filter :no_sunet_users, :only=>[ :edit_account, :update_account]
  
  # sign up form
  def new
    redirect_home_if_signed_in
    store_referred_page
    super
  end
    
  # sign up form submit method  
  def create
    if params[:user][:email].include?("@stanford.edu") || params[:user][:username].include?("@stanford.edu") # anyone who tries to register with a stanford email address or username will get an error
      redirect_to :root, :alert=>"Stanford users should not create a new account.  Login via webauth using your SunetID to access your account."
      return false
    else
      super
    end
  end

  # override devise update profile page so that user is not required to enter the current password
  def update
    
    @user = User.find(current_user.id)

    params[:user].delete(:password)  # these aren't on the form, but let's remove them anyway to prevent hacking attempt
    params[:user].delete(:password_confirmation)  # these aren't on the form, but let's remove them anyway to prevent hacking attempt
    params[:user].delete(:current_password)  # these aren't on the form, but let's remove them anyway to prevent hacking attempt
    params[:user].delete(:email)
    
    # check to be sure they aren't changing their username to something that includes @stanford.edu
    
    if params[:user][:username].include?('@stanford.edu') && params[:user][:username] != @user.username
      if @user.sunet_user?
        @user.errors.add(:base,"Your username cannot be a Stanford email address other than your own.")
      else
        @user.errors.add(:base,"Your username cannot be a Stanford email address.")
      end
      successfully_updated = false
    else
      successfully_updated = @user.update_without_password(params[:user])      
    end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to user_profile_name_path(@user.username)
    else
      render "edit"
    end

  end    
  
  # logged in user edit email/password form
  def edit_account
    @user = User.find(current_user.id)
  end

  # logged in user edit email/password submit method
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
    @user=[] if user_signed_in? && @user && @user.first==current_user  # this means they are editing their username and its themselves, that is ok
  end
  
  # ajax call to check emails
  def check_email
    return unless request.xhr?
    @user=User.where('email=?',params[:email])    
    @user=[] if user_signed_in? && @user && @user.first==current_user  # this means they are editing their email address and its themselves, that is ok
  end
      
end

# this overrides the Devise Registrations Controller, so we can do some specific things as registration time
class RegistrationsController < Devise::RegistrationsController

  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy, :edit_account, :update_account]
  before_filter :no_sunet_users, :only=>[ :edit_account, :update_account]
  before_filter :ajax_only, :only=>[:check_username,:check_email]
  
  # sign up form
  def new
    return if redirect_home_if_signed_in
    store_referred_page
    super
  end
    
  # sign up form submit method  
  def create
    @spammer=params[:email_confirm] # if this hidden field is filled in, its a spam bot
    @loadtime=params[:loadtime] # this is the time the page was rendered, if it is submitted too fast, its a spammer
    @username=params[:user][:username]
    @email=params[:user][:email]
    if Revs::Application.config.spam_reg_checks && (is_spammer?(3) || spam_registration?(@username))
      flash[:notice]=t("revs.user.spam_registration")
      redirect_to root_path

    elsif @email.include?("@stanford.edu") || @username.include?("@stanford.edu") # anyone who tries to register with a stanford email address or username will get an error
      redirect_to :root, :alert=>t('revs.authentication.stanford_create_warning')
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
    
    if params[:user][:username].include?('@stanford.edu') && @user.sunet_user? && params[:user][:username] != "#{@user.sunet}@stanford.edu"
        @user.errors.add(:base,t('revs.authentication.stanford_email_warning1'))
        successfully_updated = false
    elsif params[:user][:username].include?('@stanford.edu') && !@user.sunet_user?
        @user.errors.add(:base,t('revs.authentication.stanford_email_warning2'))
        successfully_updated = false      
    else
      successfully_updated = @user.update_without_password(user_params)      
    end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to user_path(@user.username)
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

    successfully_updated = @user.update_with_password(user_params)

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to user_path(@user.username)
    else
      render "edit_account"
    end

  end
  
  # ajax call to check usernames
  def check_username
    @user=User.where('username=?',params[:username])    
    @user=[] if user_signed_in? && @user && @user.first==current_user  # this means they are editing their username and its themselves, that is ok
  end
  
  # ajax call to check emails
  def check_email
    @user=User.where('email=?',params[:email])    
    @user=[] if user_signed_in? && @user && @user.first==current_user  # this means they are editing their email address and its themselves, that is ok
  end

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << [:email, :username, :password, :password_confirmation, :subscribe_to_mailing_list, :subscribe_to_revs_mailing_list, :registration_answer, :registration_question_number]
  end

  private
  def user_params
    params.require(:user).permit(:username, :email, :sunet, :password, :password_confirmation, :current_password, :remember_me,
                  :role, :bio, :first_name, :last_name, :public, :url, :twitter, :login,
                  :subscribe_to_mailing_list, :subscribe_to_revs_mailing_list, :active, 
                  :avatar, :avatar_cache, :remove_avatar, :login_count, :favorites_public,
                  :registration_answer, :registration_question_number)
  end

  def spam_registration?(username)
    (username =~ /\D\d\D{5}\d{3}/) == 0 # exact match for this pattern of username is a spam registrant, e.g. 'm9tlbdv809'
  end

end

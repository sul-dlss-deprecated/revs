# encoding: utf-8
require 'squash/rails' 
   
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  
   include Blacklight::Controller
   include DateHelper
   include SolrQueryHelper

   # include squash.io
   include Squash::Ruby::ControllerMethods
    
  rescue_from Exception, :with=>:exception_on_website
      
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  helper_method :application_name,:current_role,:on_home_page,:on_collections_page,:on_about_pages,:on_detail_page,:show_terms_dialog?,:tag_line,:sunet_user_signed_in?,:in_search_result?
  layout "revs"

  protect_from_forgery

  prepend_before_filter :simulate_sunet, :if=>lambda{Rails.env !='production' && !session["WEBAUTH_USER"].blank?} # to simulate sunet login in development, set a parameter in config/environments/ENVIRONMENT.rb
  before_filter :signin_sunet_user, :if=>lambda{sunet_user_signed_in? && !user_signed_in?} # signin a sunet user if they are webauthed but not yet logged into the site

  rescue_from CanCan::AccessDenied do |exception|
    not_authorized(:additional_message=>exception.message)
  end
  
  def application_name
    t('revs.digital_library')
  end
  
  def tag_line
    t('revs.tagline')
  end
  
  def previous_page
    request.referrer || root_path
  end

  def store_referred_page
    if [new_user_session_url,new_user_session_path,new_user_registration_url,new_user_registration_path,new_user_password_path,new_user_password_url,new_user_confirmation_path,new_user_confirmation_url,new_user_unlock_path,new_user_unlock_url,edit_user_password_path,edit_user_password_url].include?(previous_page) # referral pages cannot be sign in or sign up page
      session[:login_redirect] = root_path 
    else
      session[:login_redirect] = previous_page 
    end
  end
  
  def after_sign_in_path_for(resource)
    session[:login_redirect]  || root_path
  end
     
  def redirect_home_if_signed_in # if the user is already signed in and they try to go to login/reg page, just send them to the home page to prevent infinite redirects
    if user_signed_in?
      session[:login_redirect] = nil
      redirect_to root_path
      return true
    end
  end
       
  def after_sign_out_path_for(resource_or_scope) # back to home page after sign out
    root_path
  end

  def after_update_path_for(resource) # after a user updates their account info or profile, take them back to their account info page
    user_profile_name_path(current_user.username)
  end

  def no_sunet_users
    not_authorized unless (user_signed_in? && !current_user.sunet_user?)     
  end
  
  def check_for_any_user_logged_in
    not_authorized unless user_signed_in?
  end

  def check_for_user_logged_in
    not_authorized unless user_signed_in? && current_user.role?(:user)
  end
  
  def check_for_admin_logged_in
    not_authorized unless can? :administer, :all
  end

  def check_for_curator_logged_in
    not_authorized unless can? :curate, :all
  end
  
  def load_user_profile
    @id=params[:id]
    @name=params[:name]
    @user = (@id.blank? ? User.find_by_username(@name) : User.find_by_id(@id))
    profile_not_found unless @user
  end
  
  def profile_not_found
    flash[:error]=t('revs.authentication.user_not_found')
    redirect_to root_path 
  end
  
  def in_search_result?
    @previous_document || @next_document
  end
      
  def ajax_only
    unless request.xhr?
      render :nothing=>true
      return
    end
  end
  
  def set_no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  def not_authorized(params={})
    
    additional_message=params[:additional_message]
    replace_message=params[:replace_message]
    
    message = replace_message || t('revs.messages.not_authorized')
    message+=" " + additional_message unless additional_message.blank?
    
    respond_to do |format|
      format.html { redirect_to :root, :alert=>message.html_safe}
      format.xml  { render :xml => message, :status=>401 }
      format.json { render :json => {:message=>"^#{message}"}, :status=>401}
    end
    return

  end

  # only used for testing sunet in development; sets the environment variable manually for testing purposes
  def simulate_sunet
    request.env["WEBAUTH_USER"]=session["WEBAUTH_USER"] unless Rails.env=='production'
  end
  
  def signin_sunet_user
     # if we have a webauthed user who is not yet signed in, let's sign them in or create them a new user account if needed
    user=(User.where(:sunet=>request.env["WEBAUTH_USER"]).first || User.create_new_sunet_user(request.env["WEBAUTH_USER"])) 
    sign_in user unless request.path==user_session_path    
  end
  
  def sunet_user_signed_in?
    !request.env["WEBAUTH_USER"].blank?
  end
    
  def on_home_page
    request.path==root_path && params[:f].blank? && params[:q].blank?
  end

  def on_detail_page
    controller_path=='catalog' && action_name=='show'
  end
  
  def on_collections_page
    controller_path=='collection'
  end
  
  def on_about_pages
    controller_path == 'about'
  end

  def seen_terms_dialog?
    cookies[:seen_terms] || false
  end
  
  def show_terms_dialog?
    %w{production staging}.include?(Rails.env) && !seen_terms_dialog?   # we are using the terms dialog to show a warning to users who are viewing the site on production or staging
  end

  def accept_terms
    cookies[:seen_terms] = { :value => true, :expires => 1.day.from_now } # they've seen it now, don't show it for another day
    if params[:return_to].blank?
      render :nothing=>true
    else
      redirect_to params[:return_to]
    end
  end

  def current_role
    current_user ? current_user.role : 'none'
  end
  
  def current_ability
    current_user ? current_user.ability : User.new.ability
  end
        
  def exception_on_website(exception)
   
    @exception=exception
    notify_squash exception

    if Revs::Application.config.exception_error_page
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render "application/500.html.erb", :status => 500
        return false
      else
        raise(@exception)
     end
  end
      
end

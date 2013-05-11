class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  rescue_from Exception, :with=>:exception_on_website
  helper_method :application_name,:on_home_page,:on_collections_page,:on_about_pages,:on_detail_page,:show_terms_dialog?, :sunet_user_signed_in?
  layout "revs"

  prepend_before_filter :simulate_sunet, :if=>lambda{Revs::Application.config.simulate_sunet_user}
  before_filter :set_sunet_user 
  before_filter :store_current_page, :if=>lambda{!current_user} 

  def store_current_page
    session[:login_redirect] = request.path unless request.path==new_user_session_path # store the current page a user is on before they go to the login page so we can redirect after they login
  end
  
  def after_sign_in_path_for(resource)
    session[:login_redirect] || root_path # redirect to the right place after login
  end

  def after_sign_out_path_for(resource_or_scope)
    request.referrer # redirect back where they were from after loginout
  end

  def not_authorized
    
    message="You are not authorized to perform this action."
    respond_to do |format|
      format.html { redirect_to :root, :alert=>message}
      format.xml  { render :xml => message, :status=>401 }
      format.json { render :json => {:message=>"^#{message}"}, :status=>401}
    end
    return

  end

  def check_for_admin_logged_in
    not_authorized unless can? :administer, :all
  end
  
  def simulate_sunet
    request.env["WEBAUTH_USER"]='sunetuser'
  end
  
  def application_name
    "Revs Digital Library"
  end

  def set_sunet_user
    if request.env["WEBAUTH_USER"] && !user_signed_in? # if we have a webauthed user who is not yet signed in, let's sign them in or create them a new user role if needed
      user=(User.where(:sunet=>request.env["WEBAUTH_USER"]).first || User.create_new_sunet_user(request.env["WEBAUTH_USER"])) # passwords are irrelvant and never used for SUNET users
      sign_in user unless request.path==user_session_path
    end
  end
  
  def sunet_user_signed_in?
    !request.env["WEBAUTH_USER"].blank?
  end
    
  def on_home_page
    request.path==root_path && params[:f].blank?
  end

  def on_detail_page
    controller_path=='catalog' && action_name='show'
  end
  
  def on_collections_page
    controller_path=='catalog' && !on_home_page
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
        
  def exception_on_website(exception)
    @exception=exception

    RevsMailer.error_notification(:exception=>@exception).deliver unless Revs::Application.config.exception_recipients.blank? 

    if Revs::Application.config.exception_error_page
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render "500", :status => 500
      else
        raise(@exception)
     end
  end
      
  protect_from_forgery
end

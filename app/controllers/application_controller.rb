class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  rescue_from Exception, :with=>:exception_on_website
  helper_method :application_name,:request_path,:on_home_page,:show_terms_dialog?, :sunet_user
  layout "revs"

  def application_name
    "Revs Digital Library"
  end

  def sunet_user
    request.env["WEBAUTH_USER"] || ""
  end
    
  def request_path
    Rails.application.routes.recognize_path(request.path)
  end
  
  def on_home_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && params[:f].blank?
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

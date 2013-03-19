class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  rescue_from Exception, :with=>:exception_on_website
  helper_method :application_name,:request_path,:on_home_page
  layout "revs"

  before_filter :require_http
  
  def require_http
    redirect_to :protocol => "http://" if (request.ssl?) 
  end  

  def application_name
    "Revs Digital Library"
  end

  def request_path
    Rails.application.routes.recognize_path(request.path)
  end
  
  def on_home_page
    request_path[:controller] == 'catalog' && request_path[:action] == 'index' && params[:f].blank?
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

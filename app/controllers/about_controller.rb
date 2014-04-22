class AboutController < ApplicationController 

  before_filter :authorize
  
  # To create a new about page, create a partial with the URL name you want containing the actul page content
  # If your action has logic that needs to be run before the view, create a method, call "show" at the end of it, create a view partial to match,
  # and add a custom route in the routes.rb file    
  def contact
    
    @from=params[:from]
    @subject=params[:subject]
    @message=params[:message]
    @name=params[:name]
    @email=params[:email]
    @auto_response=params[:auto_response]
    params[:username]=(current_user ? current_user.username : "")
    
    if request.post?
      
      unless @message.blank? # message is required
        RevsMailer.contact_message(:params=>params,:request=>request).deliver 
        if (!@email.blank? && @auto_response == "true")
          RevsMailer.auto_response(:email=>@email,:subject=>@subject).deliver 
        end
        
        if @subject=='metadata'
          flash[:notice]=t("revs.about.contact_message_sent_about_metadata")
        else
          flash[:notice]=t("revs.about.contact_message_sent")          
        end
        
        @message=nil
        @name=nil
        @email=nil
        unless @from.blank? || request.xhr? # if this not an ajax request and we have a page to return to, go there
          redirect_to(@from)
          return
        end
        @success=true
      else # validation issue
        @success=false
        flash.now[:error]=t("revs.about.contact_error")
      end
    end
    
    request.xhr? ? render('contact',:format=>:js) : show # ajax requests need to exectue some JS, non-ajax requests render the form
    
  end

  def show
    @page_name=params[:id] || action_name # see if the page to show is specified in the ID parameter (coming via a route) or custom method (via the action name)
    @page_name='project' unless lookup_context.exists?(@page_name, 'about', true) # default to project page if requested partial doesn't exist
    @page_title=t("revs.about.#{@page_name}_title") # set the page title
    @no_nav=(@page_name=='terms_dialog' ? true : false)
    render :show
  end

  def boom
    # a quick way to raise an exception for testing exception notification
    boom!
  end
  
  protected
  def authorize
    not_authorized unless can? :read,:about_pages
  end

end
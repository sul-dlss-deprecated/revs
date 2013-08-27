class AboutController < ApplicationController 

  before_filter :authorize
  
  # To create a new about page, create a partial with the URL name you want containing the actul page content
  # If your action has logic that needs to be run before the view, create a method, call "show" at the end of it, create a view partical o match,
  # and add a custom route in the routes.rb file    
  def contact
    
    @from=params[:from]
    @subject=params[:subject]
    @name=params[:name]
    @email=params[:email]
    @message=params[:message]

    if request.post?
      
      unless @message.blank? # message is required
        RevsMailer.contact_message(:params=>params,:request=>request).deliver 
        
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
    
    request.xhr? ? render('contact.js') : show # ajax requests need to exectue some JS, non-ajax requests render the form
    
  end

  def show
    @page_name=params[:id] || action_name # see if the page to show is specified in the ID parameter (coming via a route) or custom method (via the action name)
    @page_name='project' unless lookup_context.exists?(@page_name, 'about', true) # default to project page if requested partial doesn't exist
    @page_title=t("revs.about.#{@page_name}_title") # set the page title
    @no_nav=(@page_name=='terms_dialog' ? true : false)
    render :show
  end

  protected
  def authorize
    not_authorized unless can? :read,:about_pages
  end

end
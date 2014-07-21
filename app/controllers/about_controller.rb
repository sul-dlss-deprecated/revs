class AboutController < ApplicationController 

  before_filter :authorize
  
  # To create a new about page, create a partial with the URL name you want containing the actul page content
  # If your action has logic that needs to be run before the view, create a method, call "show" at the end of it, create a view partial to match,
  # and add a custom route in the routes.rb file    
  def contact
    
    @from=params[:from]
    @subject=params[:subject]
    @message=params[:message]
    @fullname=params[:fullname]
    @email=params[:email]
    @spammer=params[:email_confirm] # if this hidden field is filled in, its a spam bot
    @loadtime=params[:loadtime] # this is the time the page was rendered, if it is submitted too fast, its a spammer
    @auto_response=params[:auto_response]
    params[:username]=(current_user ? current_user.username : "")
    
    if request.post? 
      
      if is_spammer?
        
        flash[:notice]=t("revs.about.contact_message_spambot") # show a friendly but different message to suspected spambots
        @spammer=true
        @success=true

      else

        @spammer = false

        if valid_submission? 

          RevsMailer.contact_message(:params=>params,:request=>request).deliver unless @email.blank? && @subject=='metadata' # don't bother creating a jira ticket if user doesn't supply email and its a metadata update, since we will create an anonymous flag anyway
          if (!@email.blank? && @auto_response == "true")
            RevsMailer.auto_response(:email=>@email,:subject=>@subject).deliver 
          end
          
          if @subject=='metadata'
            flash[:notice]=t("revs.about.contact_message_sent_about_metadata")
            unless @from.blank? # create a flag for this if its feedback that is coming from a specific druid page
              druid=@from.match(/\D\D\d\d\d\D\D\d\d\d\d/)
              Flag.create_new({:flag_type=>:error,:comment=>@message,:druid=>druid.to_s},current_user) unless druid.blank?
            end
          else
            flash[:notice]=t("revs.about.contact_message_sent")          
          end
          
          @message=nil
          @fullname=nil
          @email=nil
          @success=true

        else # validation issue
          
          @success=false
          flash.now[:error]=t("revs.about.contact_error")
        
        end # end check for valid submision
      
      end # end check for is spammer

    end # end check for posted
    
    if request.xhr? # ajax requests render the js 
      render('contact',:format=>:js)
    elsif request.post? && @spammer # spammers begone to the home page to make it harder to submit the form again
      redirect_to root_path
    elsif request.post? && !@from.blank? # from urls go back to where they started
      redirect_to @from
    else # otherwise just render the form
      show
    end

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
  
  def tutorials
  end

  protected
  def authorize
    not_authorized unless can? :read,:about_pages
  end

  def valid_submission?
    !@message.blank?
  end

  def is_spammer?
    !@spammer.blank? || ((Time.now - @loadtime.to_time) < 5) # user filled in a hidden form field or submitted the form in less than 7 seconds
  end

end
class AboutController < ApplicationController

  before_filter :authorize

  # To create a new about page, create a partial with the URL name you want containing the actul page content
  # If your action has logic that needs to be run before the view, create a method, call "show" at the end of it, create a view partial to match,
  # and add a custom route in the routes.rb file

  def show
    @page_name=params[:id] || action_name # see if the page to show is specified in the ID parameter (coming via a route) or custom method (via the action name)
    @page_name='project' unless lookup_context.exists?(@page_name, 'about', true) # default to project page if requested partial doesn't exist
    @page_title=t("revs.about.#{@page_name}_title") # set the page title

    if @page_name=='project'
      # get some information about all the collections and images we have so we can report on total numbers
      @total_collections=SolrDocument.all_collections.size
      if can?(:view_hidden, SolrDocument)
        @total_images=SolrDocument.total_images(:all)
        @total_hidden_images=SolrDocument.total_images(:hidden)
      else
        @total_images=SolrDocument.total_images
      end
    end
    respond_to do |format|
        format.xml  { render :nothing=>true }
        format.json { render :nothing=>true  }
        format.js { render :nothing=>true  }
        format.html { render :show}
    end
  end

  # this is the special contact us page
  def contact

    @from=params[:from]
    @subject=params[:subject]
    @message=params[:message]

    show

  end

  # this is the special page contact us requests are posted to
  def send_contact

    @from=params[:from]
    @subject=params[:subject]
    @message=params[:message]
    @fullname=params[:fullname]
    @email=params[:email]
    @spammer=params[:email_confirm] # if this hidden field is filled in, its a spam bot
    @loadtime=params[:loadtime] # this is the time the page was rendered, if it is submitted too fast, its a spammer
    @auto_response=params[:auto_response]
    params[:username]=(current_user ? current_user.username : "")

    if is_spammer?

      flash[:notice]=t("revs.about.contact_message_spambot") # show a friendly but different message to suspected spambots
      # spammers begone to the home page to make it harder to submit the form again
      redirect_to root_path

    else

      if valid_submission?

        if @subject=='metadata'  # don't bother creating a jira ticket for a metadata update, since we will create an anonymous flag anyway and add the email address and name into a private comment
          flash[:notice]=t("revs.about.contact_message_sent_about_metadata")
          unless @from.blank? # create a flag for this if its feedback that is coming from a specific druid page
            druid=@from.match(/\D\D\d\d\d\D\D\d\d\d\d/)
            Flag.create_new({:flag_type=>:error,:comment=>@message,:druid=>druid.to_s,:private_comment=>"#{@fullname}\n#{@email}"},current_user) unless druid.blank?
          end
        else # any other message gets a jira ticket
          RevsMailer.contact_message(:params=>params,:request=>request).deliver_now
          flash[:notice]=t("revs.about.contact_message_sent")
        end

        if (!@email.blank? && @auto_response == "true")
          RevsMailer.auto_response(:email=>@email,:subject=>@subject).deliver_now
        end

        @message=nil
        @fullname=nil
        @email=nil

        if request.xhr? # ajax requests render the js
          render('contact_success',:format=>:js)
        elsif !@from.blank? # from urls go back to where they started
          redirect_to @from
        else
          redirect_to root_path
        end

      else # validation issue

        flash.now[:error]=t("revs.about.contact_error")
        if request.xhr? # ajax requests render the js
          render('contact_errors',:format=>:js)
        else
          render('_contact')
        end

      end # end check for valid submision

    end # end check for is spammer

  end # end contact


  def boom
    # a quick way to raise an exception for testing exception notification
    boom!
  end

  def tutorials
    redirect_to :root
  end

  protected
  def authorize
    not_authorized unless can? :read,:about_pages
  end

  def valid_submission?
    !@message.blank?
  end

end

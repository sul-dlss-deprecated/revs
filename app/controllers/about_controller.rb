class AboutController < ApplicationController 

  # Need a action for each About page, and a partial with the same name
  # containing the actual page content. Call show to render the page
    
  def project
    show
  end
  
  def contact
    if request.post?
      @subject=params[:subject]
      @name=params[:name]
      @email=params[:email]
      @message=params[:message]
      unless @message.blank?
        RevsMailer.contact_message(:subject=>@subject,:name=>@name,:email=>@email,:message=>@message).deliver 
        flash.now[:notice]=t("revs.about.contact_message_sent")
      else
        flash.now[:error]=t("revs.about.contact_error")
      end
    end
    show
  end
  
  def terms_of_use
    show
  end
  
  def acknowledgements
    show
  end
  
  def team
    show
  end

  private
  def show
    @page_title=t("revs.about.#{action_name}_title")
    render :show
  end
    
end
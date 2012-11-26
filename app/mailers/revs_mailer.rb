class RevsMailer < ActionMailer::Base
  default from: "no-reply@revslib.stanford.edu"

  def contact_message(opts={})
    @message=opts[:message]
    @email=opts[:email]
    @name=opts[:name]
    @subject=opts[:subject]
    mail(:to=>Revs::Application.config.contact_us_recipients[@subject], :subject=>"Contact Message from Revs Digital Library - #{@subject}") 
  end

  def error_notification(opts={})
    @exception=opts[:exception]
    @mode=Rails.env
    mail(:to=>Revs::Application.config.exception_recipients, :subject=>"Revs Digital Library Exception Notification running in #{@mode} mode")
  end
  
end

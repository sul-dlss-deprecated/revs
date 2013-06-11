class RevsMailer < ActionMailer::Base
  default from: "no-reply@revslib.stanford.edu"

  def contact_message(opts={})
    params=opts[:params]
    @request=opts[:request]
    @message=params[:message]
    @email=params[:email]
    @name=params[:name]
    @subject=params[:subject]
    @from=params[:from]
    to=Revs::Application.config.contact_us_recipients[@subject]
    cc=Revs::Application.config.contact_us_cc_recipients[@subject]
    mail(:to=>to, :cc=>cc, :subject=>"Contact Message from Revs Digital Library - #{@subject}") 
  end

  def mailing_list_signup(opts={})
    mail(:to=>"revs-program-join@lists.stanford.edu",:from=>opts[:from],:subject=>"Request to be added to Revs Mailing List",:body=>"Subscribe")
  end

  def revs_institute_mailing_list_signup(opts={})
    mail(:to=>"news@revsinstitute.org",:from=>opts[:from],:subject=>"Request to be added to Revs Institute Mailing List from Revs Digital Library",:body=>"User at #{opts[:from]} wishes to subscribe to the Revs Institute Mailing List")
  end
  
  def error_notification(opts={})
    @exception=opts[:exception]
    @mode=Rails.env
    mail(:to=>Revs::Application.config.exception_recipients, :subject=>"Revs Digital Library Exception Notification running in #{@mode} mode")
  end
  
end

class RevsMailer < ActionMailer::Base

  helper :application
  include ApplicationHelper
  default from: "no-reply@revslib.stanford.edu"

  def contact_message(opts={})
    params=opts[:params]
    @request=opts[:request]
    @message=params[:message]
    @email=params[:email]
    @fullname=params[:fullname]
    @subject=params[:subject]
    @from=params[:from]
    @username=params[:username]
    to=Revs::Application.config.contact_us_recipients[@subject]
    cc=Revs::Application.config.contact_us_cc_recipients[@subject]
    mail(:to=>to, :cc=>cc, :subject=>"Contact Message from Revs Digital Library - #{@subject}") unless to.nil? || !valid_email?(to) # only send an email if we have a valid to address (if user has tampered with subject params, this might not be the case)
  end

  def auto_response(opts={})
    @email=opts[:email]
    @subject=opts[:subject]
    mail(:to=>@email,:subject=>I18n.t('revs.contact.thanks')) if valid_email?(@email)
  end
  
  def flag_resolved(flag)
    @flag=flag
    mail(:to=>flag.user.email,:subject=>I18n.t('revs.flags.resolved_message')) if flag.user && flag.user.email && valid_email?(flag.user.email)
  end
  
  def mailing_list_signup(opts={})
    mail(:to=>"revs-program-join@lists.stanford.edu",:from=>opts[:from],:subject=>"Request to be added to the Revs Program Mailing List",:body=>"Subscribe")
  end
  
end

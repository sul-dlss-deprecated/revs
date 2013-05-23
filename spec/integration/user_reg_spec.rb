require 'spec_helper'

describe("User Registration",:type=>:request,:integration=>true) do
  
  before :each do
    @password='password'
    RevsMailer.stub_chain(:mailing_list_signup,:deliver).and_return('a mailer')
  end
  
  it "should register a new user with the default role" do

    RevsMailer.should_not_receive(:mailing_list_signup)

    @email_address='test@test.com'    
    # regsiter a new user
    visit new_user_registration_path
    fill_in 'user_email', :with=> @email_address
    fill_in 'user_password', :with=> @password
    fill_in 'user_password_confirmation', :with=> @password    
    click_button 'Sign up'
    
    # check the database
    user=User.last
    user.role.should == 'user'
    user.email.should == @email_address

  end

  it "should register a new user and send an email to join the Revs Program list if selected" do

      RevsMailer.should_receive(:mailing_list_signup)
        
      @email_address='test2@test.com'    
      # regsiter a new user
      visit new_user_registration_path
      fill_in 'user_email', :with=> @email_address
      fill_in 'user_password', :with=> @password
      fill_in 'user_password_confirmation', :with=> @password    
      check 'user_subscribe_to_mailing_list'
      click_button 'Sign up'

      # check the database
      user=User.last
      user.role.should == 'user'
      user.email.should == @email_address

    end
  
end
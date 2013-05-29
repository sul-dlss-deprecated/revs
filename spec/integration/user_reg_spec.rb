require 'spec_helper'

describe("User Registration",:type=>:request,:integration=>true) do
  
  before :each do
    @password='password'
    RevsMailer.stub_chain(:mailing_list_signup,:deliver).and_return('a mailer')
  end
  
  it "should register a new user with the default role and defaulting to public profile as hidden" do

    RevsMailer.should_not_receive(:mailing_list_signup)

    @username='testing'
    @email="#{@username}@test.com"
    # regsiter a new user
    visit new_user_registration_path
    fill_in 'user_email', :with=> @email
    fill_in 'user_username', :with=> @username
    fill_in 'user_password', :with=> @password
    fill_in 'user_password_confirmation', :with=> @password
    click_button 'Sign up'
    
    current_path.should == root_path
    page.should have_content 'A message with a confirmation link has been sent to your email address. Please open the link to activate your account.'
    
    # check the database
    user=User.last
    user.role.should == 'user'
    user.username.should == @username
    user.email.should == @email
    user.public.should == false

  end

  it "should register a new user and send an email to join the Revs Program list if selected" do

      RevsMailer.should_receive(:mailing_list_signup)
        
      @username='testing2'
      @email="#{@username}@test.com" 
      # regsiter a new user
      visit new_user_registration_path
      fill_in 'user_email', :with=> @email
      fill_in 'user_username', :with=> @username
      fill_in 'user_password', :with=> @password
      fill_in 'user_password_confirmation', :with=> @password    
      check 'user_subscribe_to_mailing_list'
      click_button 'Sign up'

      current_path.should == root_path
      page.should have_content 'A message with a confirmation link has been sent to your email address. Please open the link to activate your account.'

      # check the database
      user=User.last
      user.role.should == 'user'
      user.username.should == @username
      user.email.should == @email

    end
    
    it "should NOT register a new user via the web page if they have a Stanford email address" do

        RevsMailer.should_not_receive(:mailing_list_signup)

        @username='testguy'
        @email="#{@username}@stanford.edu" 
        # regsiter a new stanford user
        visit new_user_registration_path
        fill_in 'user_email', :with=> @email
        fill_in 'user_username', :with=> @username
        fill_in 'user_password', :with=> @password
        fill_in 'user_password_confirmation', :with=> @password    
        click_button 'Sign up'

        current_path.should == root_path
        page.should have_content 'Stanford users should not create a new account.'

        # check the database
        user=User.last
        user.username.should_not == @username
        user.email.should_not == @email

      end
      
  
end
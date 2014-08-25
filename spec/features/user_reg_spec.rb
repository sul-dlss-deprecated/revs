require 'spec_helper'

describe("User Registration",:type=>:request,:integration=>true) do
  
  before :each do
    @password='password'
    RevsMailer.stub_chain(:mailing_list_signup,:deliver).and_return('a mailer')
    RevsMailer.stub_chain(:revs_institute_mailing_list_signup,:deliver).and_return('a mailer')
  end
  
  it "should register a new user with the default role and defaulting to public profile as hidden" do

    RevsMailer.should_not_receive(:mailing_list_signup)
    RevsMailer.should_not_receive(:revs_institute_mailing_list_signup)

    @username='testing'
    @email="#{@username}@test.com"
    # regsiter a new user
    visit new_user_registration_path
    fill_in 'register-email', :with=> @email
    fill_in 'register-username', :with=> @username
    fill_in 'user_password', :with=> @password
    fill_in 'user_password_confirmation', :with=> @password
    click_button 'Sign up'
    
    should_register_ok
    
    # check the database
    user=User.last
    user.role.should == 'user'
    user.username.should == @username
    user.email.should == @email
    user.public.should == false
    
    favorites=Gallery.last
    favorites.gallery_type.should == 'favorites'
    favorites.user_id.should == user.id

  end

  it "should register a new user and send an email to join the Revs Program list if selected" do

      RevsMailer.should_receive(:mailing_list_signup)
      RevsMailer.should_not_receive(:revs_institute_mailing_list_signup)
        
      @username='testing2'
      @email="#{@username}@test.com" 
      # register a new user
      register_new_user(@username,@password,@email)    
      check 'user_subscribe_to_mailing_list'
      click_button 'Sign up'

      should_register_ok
    
      # check the database
      user=User.last
      user.role.should == 'user'
      user.username.should == @username
      user.email.should == @email

    end

    it "should register a new user and send an email to join the Revs Institute Mailing list if selected" do

        RevsMailer.should_receive(:revs_institute_mailing_list_signup)
        RevsMailer.should_not_receive(:mailing_list_signup)

        @username='testing3'
        @email="#{@username}@test.com" 
        # register a new user
        register_new_user(@username,@password,@email) 
        check 'user_subscribe_to_revs_mailing_list'
        click_button 'Sign up'

        should_register_ok
       
        # check the database
        user=User.last
        user.role.should == 'user'
        user.username.should == @username
        user.email.should == @email

      end
 
     it "should create a username as the sunetID when a new Stanford user signs in via webauth" do
    
      @username="somesunet"

      User.where(:username=>@username).size.should == 0 # doesn't exist yet

      # try and create a new stanford user with this sunetid, which does not exist in database
      new_user=User.create_new_sunet_user(@username)
      new_user.sunet.should == @username
      new_user.username.should == @username
      new_user.sunet_user?.should be_true
      new_user.email.should == "#{@username}@stanford.edu"

    end

     it "should create a username as the sunetID when a new Stanford user signs in via webauth, making it longer to have it be at least 5 characters" do
    
      @username="pet"

      User.where(:username=>@username).size.should == 0 # doesn't exist yet

      # try and create a new stanford user with this sunetid, which does not exist in database
      new_user=User.create_new_sunet_user(@username)
      new_user.sunet.should == @username
      new_user.username.should == "#{@username}12"
      new_user.sunet_user?.should be_true
      new_user.email.should == "#{@username}@stanford.edu"

    end

    it "should create a unique username based on the new Stanford users sunetID if a regular user already happens to be registered with that sunet ID as a username" do
    
      @username="somesunet"
      @email="#{@username}@test.com" 
      register_new_user(@username,@password,@email) 
      click_button 'Sign up' 

      should_register_ok

      # now try and create a new stanford user with this same sunetid as an already registered users and see if it uniquifies it
      new_user=User.create_new_sunet_user(@username)
      new_user.sunet.should == @username
      new_user.username.should == "#{@username}_1"
      new_user.sunet_user?.should be_true
      new_user.email.should == "#{@username}@stanford.edu"

    end

    it "should NOT register a new user via the web page if they have a Stanford email address or try a username with a Stanford email address" do

        RevsMailer.should_not_receive(:mailing_list_signup)
        RevsMailer.should_not_receive(:revs_institute_mailing_list_signup)

        @username='testguy'
        @email="#{@username}@stanford.edu" 

        # try to register a new user with a stanford email address
        register_new_user(@username,@password,@email) 
        click_button 'Sign up'

        current_path.should == root_path
        page.should have_content 'Stanford users should not create a new account.'

        # check the database
        user=User.last
        user.username.should_not == @username
        user.email.should_not == @email

        # try to register a new stanford user with a stanford email address as the username
        visit new_user_registration_path
        register_new_user(@email,@password,"#{@username}@example.com") 
        click_button 'Sign up'

        current_path.should == root_path
        page.should have_content 'Stanford users should not create a new account.'

        # check the database
        user=User.last
        user.username.should_not == @email
        user.email.should_not == "#{@username}@example.com"
        
      end

      it "should NOT allow a user to reset their password if they have a Stanford email address" do

          # try to reset the password of an existing stanford user
          visit new_user_password_path
          fill_in 'user_login', :with=> sunet_login
          click_button 'submit'

          current_path.should == root_path
          page.should have_content 'Stanford users need to login via webauth with their SunetID to access their account. You cannot reset your SunetID password here.'

        end      
  
end
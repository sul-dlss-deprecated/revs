require "rails_helper"

describe("User Registration",:type=>:request,:integration=>true) do
  
  before :each do
    @password='password'
    RevsMailer.stub_chain(:mailing_list_signup,:deliver).and_return('a mailer')
  end
  
  it "should register a new user with the default role and defaulting to public profile as hidden" do

    expect(RevsMailer).not_to receive(:mailing_list_signup)

    @username='testing'
    @email="#{@username}@test.com"
    # regsiter a new user
    visit new_user_registration_path
    fill_in 'register-email', :with=> @email
    fill_in 'register-username', :with=> @username
    fill_in 'user_password', :with=> @password
    fill_in 'user_password_confirmation', :with=> @password
    sleep 6.seconds
    click_button 'Sign up'
    
    should_register_ok
    
    # check the database
    user=User.last
    expect(user.role).to eq('user')
    expect(user.username).to eq(@username)
    expect(user.email).to eq(@email)
    expect(user.public).to eq(false)
    
    favorites=Gallery.last
    expect(favorites.gallery_type).to eq('favorites')
    expect(favorites.user_id).to eq(user.id)

  end

  it "should register a new user and send an email to join the Revs Program list if selected" do

      expect(RevsMailer).to receive(:mailing_list_signup)
        
      @username='testing2'
      @email="#{@username}@test.com" 
      # register a new user
      register_new_user(@username,@password,@email)    
      check 'user_subscribe_to_mailing_list'
      sleep 6.seconds
      click_button 'Sign up'

      should_register_ok
    
      # check the database
      user=User.last
      expect(user.role).to eq('user')
      expect(user.username).to eq(@username)
      expect(user.email).to eq(@email)

    end
 
     it "should create a username as the sunetID when a new Stanford user signs in via webauth" do
    
      @username="somesunet"

      expect(User.where(:username=>@username).size).to eq(0) # doesn't exist yet

      # try and create a new stanford user with this sunetid, which does not exist in database
      new_user=User.create_new_sunet_user(@username)
      expect(new_user.sunet).to eq(@username)
      expect(new_user.username).to eq(@username)
      expect(new_user.sunet_user?).to be_truthy
      expect(new_user.email).to eq("#{@username}@stanford.edu")

    end

     it "should create a username as the sunetID when a new Stanford user signs in via webauth, making it longer to have it be at least 5 characters" do
    
      @username="pet"

      expect(User.where(:username=>@username).size).to eq(0) # doesn't exist yet

      # try and create a new stanford user with this sunetid, which does not exist in database
      new_user=User.create_new_sunet_user(@username)
      expect(new_user.sunet).to eq(@username)
      expect(new_user.username).to eq("#{@username}12")
      expect(new_user.sunet_user?).to be_truthy
      expect(new_user.email).to eq("#{@username}@stanford.edu")

    end

    it "should create a unique username based on the new Stanford users sunetID if a regular user already happens to be registered with that sunet ID as a username" do
    
      @username="somesunet"
      @email="#{@username}@test.com" 
      register_new_user(@username,@password,@email) 
      sleep 6.seconds
      click_button 'Sign up' 

      should_register_ok

      # now try and create a new stanford user with this same sunetid as an already registered users and see if it uniquifies it
      new_user=User.create_new_sunet_user(@username)
      expect(new_user.sunet).to eq(@username)
      expect(new_user.username).to eq("#{@username}_1")
      expect(new_user.sunet_user?).to be_truthy
      expect(new_user.email).to eq("#{@username}@stanford.edu")

    end

    it "should NOT register a new user via the web page if they have a Stanford email address or try a username with a Stanford email address" do

        expect(RevsMailer).not_to receive(:mailing_list_signup)

        @username='testguy'
        @email="#{@username}@stanford.edu" 

        # try to register a new user with a stanford email address
        register_new_user(@username,@password,@email) 
        sleep 6.seconds

        click_button 'Sign up'

        expect(current_path).to eq(root_path)
        expect(page).to have_content 'Stanford users should not create a new account.'

        # check the database
        user=User.last
        expect(user.username).not_to eq(@username)
        expect(user.email).not_to eq(@email)

        # try to register a new stanford user with a stanford email address as the username
        visit new_user_registration_path
        register_new_user(@email,@password,"#{@username}@example.com") 
        sleep 6.seconds

        click_button 'Sign up'

        expect(current_path).to eq(root_path)
        expect(page).to have_content 'Stanford users should not create a new account.'

        # check the database
        user=User.last
        expect(user.username).not_to eq(@email)
        expect(user.email).not_to eq("#{@username}@example.com")
        
      end

      it "should NOT allow a user to reset their password if they have a Stanford email address" do

          # try to reset the password of an existing stanford user
          visit new_user_password_path
          fill_in 'user_login', :with=> sunet_login
          click_button 'submit'

          expect(current_path).to eq(root_path)
          expect(page).to have_content 'Stanford users need to login via webauth with their SunetID to access their account. You cannot reset your SunetID password here.'

      end      
  
      it "should detect a spammer as someone who submits the form too quickly" do

        user_count = User.count
        @username='testing2'
        @email="#{@username}@test.com" 
        # register a new user
        register_new_user(@username,@password,@email)    

        click_button 'Sign up'

        expect(page).to have_content(I18n.t("revs.about.contact_message_spambot"))
        expect(current_path).to eq(root_path)
        expect(User.count).to eq(user_count) # no new users
        
      end

      it "should detect a spammer as someone who fills in the hidden form field" do

        user_count = User.count
        @username='testing2'
        @email="#{@username}@test.com" 
        # register a new user
        register_new_user(@username,@password,@email)  
        within('#main-container') do    
          fill_in 'email_confirm', :with=>'hidden field'
        end
        
        sleep 6.seconds

        click_button 'Sign up'
        
        expect(page).to have_content(I18n.t("revs.about.contact_message_spambot"))
        expect(current_path).to eq(root_path)
        expect(User.count).to eq(user_count) # no new users

      end
      
end
require 'spec_helper'

describe("Editing of logged in users",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
    
  it "should allow a logged in user to update their profile" do
   
    new_bio='I am super cool.'
    new_last_name='Rockin'
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    visit user_profile_name_path(user_account.username)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content("#{user_account.full_name}")
    click_link 'Update your profile'

    fill_in 'user_bio', :with=>new_bio
    fill_in 'user_last_name', :with=>new_last_name
    click_button 'submit'
    
    current_path.should == user_profile_name_path(user_account.username)
    page.should have_content(new_bio)
    page.should have_content(new_last_name)
    
    # check database
    user_account=User.find_by_username(user_login)
    user_account.bio.should == new_bio
    user_account.last_name.should == new_last_name
    
  end

  it "should not allow a logged in user to update their username to a Stanford email address" do
   
    new_username='somemail@stanford.edu'
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    visit user_profile_name_path(user_account.username)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content("#{user_account.full_name}")
    click_link 'Update your profile'

    fill_in 'register-username', :with=>new_username
    click_button 'submit'
    
    page.should have_content("Your username cannot be a Stanford email address.")
    
    # check database
    user_account=User.find_by_username(user_login)
    user_account.username.should_not == new_username
    
  end
  
  it "should allow a logged in user to update their password" do
   
    new_password='new_password'
    user_account=User.find_by_username(user_login)
    user_account.login_count.should == 0
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    user_account.login_count.should == 1
    
    visit user_profile_name_path(user_account.username)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content("#{user_account.full_name}")
    click_link 'Change your password'

    fill_in 'user_password', :with=>new_password
    fill_in 'user_password_confirmation', :with=>new_password
    fill_in 'user_current_password', :with=>login_pw

    click_button 'submit'
    
    current_path.should == user_profile_name_path(user_account.username)

    # now try and login again with old password, this should fail
    logout
    login_as(user_login)
    current_path.should == new_user_session_path
    page.should have_content('Your account was not found or your password was incorrect.')
    
    # login with new password, this should succeed
    visit new_user_session_path
    fill_in "user_login", :with => user_login
    fill_in "user_password", :with => new_password
    click_button "submit"
    visit user_profile_name_path(user_account.username)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content("#{user_account.full_name}")
    
  end

  it "should allow a sunet user to login and edit their profile but should not let them edit their email or password" do

    new_bio='I work at Stanford. That makes me smart.'
    new_last_name='Professor'
    sunet_account=User.find_by_username(sunet_login)
    sunet_account.login_count.should == 0
    
    visit webauth_login_path
    sunet_account=User.find_by_username(sunet_login)
    sunet_account.login_count.should == 1
    
    visit user_profile_name_path(sunet_account.username) # user profile page
    page.should have_content sunet_account.full_name
    page.should_not have_content 'Change your password' # we shouldn't have the edit password link
    page.should_not have_content 'Change your email address' # we shouldn't have the edit email address link
    
    click_link 'Update your profile'

    fill_in 'user_bio', :with=>new_bio
    fill_in 'user_last_name', :with=>new_last_name
    click_button 'submit'
    
    current_path.should == user_profile_name_path(sunet_account.username)
    page.should have_content(new_bio)
    page.should have_content(new_last_name)
    
    # check database
    user_account=User.find_by_username(sunet_login)
    user_account.bio.should == new_bio
    user_account.last_name.should == new_last_name   
     
    # confirm we can't get to the edit password/email page via the URL either
    visit edit_user_account_path
    current_path.should == root_path
    page.should have_content 'You are not authorized to perform this action.'
    
    # sign out
    visit user_profile_name_path(sunet_account.username) # user profile page
    logout
    current_path.should == root_path
    page.should_not have_content sunet_account.full_name
    
  end

  it "should not allow a logged in stanford user to update their username to a different Stanford email address" do
   
    new_username='somemail@stanford.edu'

    visit webauth_login_path
    sunet_account=User.find_by_username(sunet_login)
    
    visit user_profile_name_path(sunet_account.username) # user profile page    
    click_link 'Update your profile'

    fill_in 'register-username', :with=>new_username
    click_button 'submit'
        
    page.should have_content("Your username cannot be a Stanford email address other than your own.")
    
    # check database
    sunet_account=User.find_by_username(sunet_login)
    sunet_account.username.should_not == new_username
    
  end
  
end

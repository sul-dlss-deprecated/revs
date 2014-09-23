require "rails_helper"

describe("Editing of logged in users",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
    
  it "should allow a logged in user to update their profile" do
   
    new_bio='I am super cool.'
    new_last_name='Rockin'
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    visit user_path(user_account.username)
    expect(page).to have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    expect(page).to have_content("#{user_account.full_name}")
    click_link 'Update your profile'

    fill_in 'user_bio', :with=>new_bio
    fill_in 'user_last_name', :with=>new_last_name
    click_button 'submit'
    
    expect(current_path).to eq(user_path(user_account.username))
    expect(page).to have_content(new_bio)
    expect(page).to have_content(new_last_name)
    
    # check database
    user_account=User.find_by_username(user_login)
    expect(user_account.bio).to eq(new_bio)
    expect(user_account.last_name).to eq(new_last_name)
    
  end

  it "should not allow a logged in user to update their username to a Stanford email address" do
   
    new_username='somemail@stanford.edu'
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    visit user_path(user_account.username)
    expect(page).to have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    expect(page).to have_content("#{user_account.full_name}")
    click_link 'Update your profile'

    fill_in 'register-username', :with=>new_username
    click_button 'submit'
    
    expect(page).to have_content("Your username cannot be a Stanford email address.")
    
    # check database
    user_account=User.find_by_username(user_login)
    expect(user_account.username).not_to eq(new_username)
    
  end
  
  it "should allow a logged in user to update their password" do
   
    new_password='new_password'
    user_account=User.find_by_username(user_login)
    expect(user_account.login_count).to eq(0)
    
    login_as(user_login)
    user_account=User.find_by_username(user_login)
    expect(user_account.login_count).to eq(1)
    
    visit user_path(user_account.username)
    expect(page).to have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    expect(page).to have_content("#{user_account.full_name}")
    click_link 'Change your password'

    fill_in 'user_password', :with=>new_password
    fill_in 'user_password_confirmation', :with=>new_password
    fill_in 'user_current_password', :with=>login_pw

    click_button 'submit'
    
    expect(current_path).to eq(user_path(user_account.username))

    # now try and login again with old password, this should fail
    logout
    login_as(user_login)
    expect(current_path).to eq(new_user_session_path)
    expect(page).to have_content('Your account was not found or your password was incorrect.')
    
    # login with new password, this should succeed
    visit new_user_session_path
    fill_in "user_login", :with => user_login
    fill_in "user_password", :with => new_password
    click_button "submit"
    visit user_path(user_account.username)
    expect(page).to have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    expect(page).to have_content("#{user_account.full_name}")
    
  end

  it "should allow a sunet user to login and edit their profile but should not let them edit their email or password" do

    new_bio='I work at Stanford. That makes me smart.'
    new_last_name='Professor'
    sunet_account=User.find_by_username(sunet_login)
    expect(sunet_account.login_count).to eq(0)
    
    visit webauth_login_path
    sunet_account=User.find_by_username(sunet_login)
    expect(sunet_account.login_count).to eq(1)
    
    visit user_path(sunet_account.username) # user profile page
    expect(page).to have_content sunet_account.full_name
    expect(page).not_to have_content 'Change your password' # we shouldn't have the edit password link
    expect(page).not_to have_content 'Change your email address' # we shouldn't have the edit email address link
    
    click_link 'Update your profile'

    fill_in 'user_bio', :with=>new_bio
    fill_in 'user_last_name', :with=>new_last_name
    click_button 'submit'
    
    expect(current_path).to eq(user_path(sunet_account.username))
    expect(page).to have_content(new_bio)
    expect(page).to have_content(new_last_name)
    
    # check database
    user_account=User.find_by_username(sunet_login)
    expect(user_account.bio).to eq(new_bio)
    expect(user_account.last_name).to eq(new_last_name)   
     
    # confirm we can't get to the edit password/email page via the URL either
    visit edit_user_account_path
    expect(current_path).to eq(root_path)
    expect(page).to have_content 'You are not authorized to perform this action.'
    
    # sign out
    visit user_path(sunet_account.username) # user profile page
    logout
    expect(current_path).to eq(root_path)
    expect(page).not_to have_content sunet_account.full_name
    
  end

  it "should not allow a logged in stanford user to update their username to a different Stanford email address" do
   
    new_username='somemail@stanford.edu'

    visit webauth_login_path
    sunet_account=User.find_by_username(sunet_login)
    
    visit user_path(sunet_account.username) # user profile page    
    click_link 'Update your profile'

    fill_in 'register-username', :with=>new_username
    click_button 'submit'
        
    expect(page).to have_content("Your username cannot be a Stanford email address other than your own.")
    
    # check database
    sunet_account=User.find_by_username(sunet_login)
    expect(sunet_account.username).not_to eq(new_username)
    
  end
  
end

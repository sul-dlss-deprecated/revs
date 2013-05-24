require 'spec_helper'

describe("Logged in users",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
    
  it "should allow a user to login" do
    login_as(user_login)
    current_path.should == root_path
    page.should have_content(user_login) # username at top of page  
    page.should have_content('Signed in successfully.') # sign in message
    page.should_not have_content('Admin') # no admin menu on top of page
    page.should_not have_content('Curator') # no curator menu on top of page
  end

  it "should not allow a sunet user to login via the login form" do
    login_as(sunet_login)
    current_path.should == root_path
    page.should have_content('Stanford users must use webauth via SunetID to access their accounts.')
    page.should_not have_content(sunet_login) # username at top of page  
  end
  
  it "should allow a user to return to the page they were on and not see the admin or curator interface" do
    starting_page=catalog_path('qb957rw1430')
    visit starting_page
    should_not_allow_flagging
    should_not_allow_annotations
    login_as(user_login)
    current_path.should == starting_page
    should_allow_flagging
    should_allow_annotations    
    should_not_allow_admin_section
    should_not_allow_curator_section   
  end
  
  it "should not show the public profile of a user who does not want their profile public, but should show the public profile page for users who do have it set as public" do
    admin_account=User.find_by_email(admin_login)
    user_account=User.find_by_email(user_login)
    admin_account.public.should == false
    user_account.public.should == true

    # admin user profile is not public
    visit user_profile_id_path(admin_account.id)
    current_path.should == root_path
    page.should have_content 'The user was not found or their profile is not public.'

    # regular user profile is public and should be available via ID or full name
    visit user_profile_id_path(user_account.id)
    current_path.should == user_profile_id_path(user_account.id)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}
    visit user_profile_name_path(user_account.first_name + '.' + user_account.last_name)
    current_path.should == user_profile_name_path(user_account.first_name + '.' + user_account.last_name)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}    
  end

  it "should show a disambiguation page when two users with public profiles have exactly the same first name and last name" do
    admin_account=User.find_by_email(admin_login)
    user_account=User.find_by_email(user_login)
    admin_account.public.should == false
    user_account.public.should == true

    # update the admin account so they have the same first name/last name as the regular user and their profile is public
    admin_account.public = true
    admin_account.first_name=user_account.first_name
    admin_account.last_name=user_account.last_name
    admin_account.save!
    
    # now visit the named path public profile and see if we get the disambiguation page
    visit user_profile_name_path(user_account.first_name + '.' + user_account.last_name)
    current_path.should == user_profile_name_path(user_account.first_name + '.' + user_account.last_name)
    page.should have_content('Please select a user')
    page.should have_content("2 users were found with the name #{user_account.full_name}")
  end
  
  it "should not show my user profile page is there is no user logged in" do
    visit my_user_profile_path
    current_path.should == root_path
    page.should have_content 'You are not authorized to perform this action.'
  end

  it "should show my user profile page when logged in, even if your profile is marked as private" do
    # admin user profile is not public
    admin_account=User.find_by_email(admin_login)
    admin_account.public.should == false
    login_as(admin_login)

    visit my_user_profile_path
    current_path.should == my_user_profile_path
    [admin_account.full_name,admin_account.bio].each {|content| page.should have_content content}
    page.should have_content 'Profile page Private'
  end
  
end
require 'spec_helper'

describe("Logged in users",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
    
  it "should allow a user to login" do
    login_as(user_login)
    current_path.should == root_path
    page.should have_content('User Web') # username at top of page  
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
    admin_account=User.find_by_username(admin_login)
    user_account=User.find_by_username(user_login)
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
    visit user_profile_name_path(user_account.username)
    current_path.should == user_profile_name_path(user_account.username)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}    
  end
  
  it "should show my user profile page when logged in, even if your profile is marked as private" do
    # admin user profile is not public
    admin_account=User.find_by_username(admin_login)
    admin_account.public.should == false
    login_as(admin_login)

    visit user_profile_name_path(admin_account.username)
    current_path.should == user_profile_name_path(admin_account.username)
    [admin_account.full_name,admin_account.bio].each {|content| page.should have_content content}
    page.should have_content 'private'
  end

  it "should show link to annotations made by user on that user's profile page, only if user has made annotations " do
    login_as(user_login) # this user has annotations
    visit user_profile_name_path(user_login)
    current_path.should == user_profile_name_path(user_login)
    page.should have_content 'View your annotations'
    logout

    login_as(curator_login) # this user does not have annotations
    visit user_profile_name_path(curator_login)
    current_path.should == user_profile_name_path(curator_login)
    page.should_not have_content 'View your annotations'
  end

  it "should show correct number of annotations made by user on that user's profile page, along with most recent annotations and flags" do
    login_as(admin_login)
    visit user_profile_name_path(admin_login)
    current_path.should == user_profile_name_path(admin_login)
    page.should have_content 'Annotations 02'
    logout

    login_as(user_login)
    visit  user_profile_name_path(user_login)
    current_path.should ==  user_profile_name_path(user_login)
    ["Annotations 01","air intake?","Flags","Sebring 12 Hour, Green Park..."].each {|title| page.should have_content(title)}
    
  end

  it "should show a profile preview link on edit profile page, but only if user profile is private" do
    login_as(admin_login) # profile page is private
    visit edit_user_registration_path
    current_path.should == edit_user_registration_path
    page.should have_link('Preview', href: user_profile_name_path(admin_login))
    logout

    login_as(user_login) # profile page is public
    visit edit_user_registration_path
    current_path.should == edit_user_registration_path
    page.should_not have_link('Preview', href: user_profile_name_path(user_login))
  end

  it "show the logged in users annotations/flags with their full name, even if the profile is private" do
    login_as(admin_login)
    admin_account=User.find_by_username(admin_login)
    admin_account.public.should == false
    visit user_annotations_path(admin_account.username)
    page.should have_content "#{admin_account.full_name}'s Annotations"
    page.should have_content "Guy in the background looking sideways"
    visit user_flags_path(admin_account.username)    
    page.should have_content "#{admin_account.full_name}'s Flags"
    page.should have_content "This user does not have any flags."    
  end

  it "show a non logged in users annotations/flags with just their username, even if the profile is private" do
    admin_account=User.find_by_username(admin_login)
    admin_account.public.should == false
    visit user_annotations_path(admin_account.username)
    page.should_not have_content admin_account.full_name
    page.should have_content "#{admin_account.username}'s Annotations"
    page.should have_content "Guy in the background looking sideways"
    visit user_flags_path(admin_account.username)    
    page.should have_content "#{admin_account.username}'s Flags"
    page.should have_content "This user does not have any flags."    
  end

  it "show a non logged in users annotations/flags with their full name if their profile is public" do
    user_account=User.find_by_username(user_login)
    user_account.public.should == true
    visit user_annotations_path(user_account.username)    
    page.should have_content "#{user_account.full_name}'s Annotations"
    page.should have_content "air intake?"
    visit user_flags_path(user_account.username)    
    page.should have_content "#{user_account.full_name}'s Flags"
    page.should have_content "user comment"    
  end
  
  it "should show only the dashboard links appropriate for role of user" do
    login_as(admin_login)
    visit user_profile_name_path(admin_login)
    current_path.should == user_profile_name_path(admin_login)
    page.should have_content 'User Dashboard'
    page.should have_content 'Curator Dashboard'
    page.should have_content 'Admin Dashboard'
    logout

    login_as(curator_login)
    visit user_profile_name_path(curator_login)
    current_path.should ==  user_profile_name_path(curator_login)
    page.should have_content 'User Dashboard'
    page.should have_content 'Curator Dashboard'
    page.should_not have_content 'Admin Dashboard'
    logout

    login_as(user_login)
    visit user_profile_name_path(user_login)
    current_path.should ==  user_profile_name_path(user_login)
    page.should have_content 'User Dashboard'
    page.should_not have_content 'Curator Dashboard'
    page.should_not have_content 'Admin Dashboard'
  end

end

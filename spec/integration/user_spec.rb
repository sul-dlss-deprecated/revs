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
    
    it "should not show the public profile of a user who does not want their profile public" do
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
    
end
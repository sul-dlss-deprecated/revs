require 'spec_helper'

describe("Admin Section",:type=>:request,:integration=>true) do
  
  before :each do
    logout
  end
  
  it "should allow an admin user to login" do
      login_as(admin_login)
      current_path.should == root_path
      page.should have_content('Admin Stanford')    # name at top of page  
      page.should have_content('Signed in successfully.') # sign in message
      page.should have_content('Admin') # admin menu on top of page
      page.should have_content('Curator') # curator menu on top of page
    end

    it "should allow an admin user to return to the page they were on and then see the admin interface and curator interface" do
      starting_page=catalog_path('qb957rw1430')
      visit starting_page
      should_not_allow_flagging
      should_not_allow_annotations      
      login_as(admin_login)
      current_path.should == starting_page
      should_allow_flagging
      should_allow_annotations    
      should_allow_admin_section
      should_allow_curator_section
    end
   
   describe "Administer users" do
   
     it "should show all users, and be able to edit a user" do

       new_lastname='NewLastName'
       new_role='curator'
       
       # user role should be "user"
       user=User.find_by_username(user_login)
       user.role.should == 'user'

       login_as(admin_login)
       visit admin_users_path
       ["#{user_login}","#{curator_login}","#{admin_login}"].each {|account| page.should have_content(account)} # all accounts should be displayed
       page.should have_content(user.full_name) # should show the current user's last name
       page.should_not have_content(new_lastname) # show not show the new last name we are about to +enter+
       
       # let's edit them to make them a curator
       click_link "edit-#{user.id}"
       current_path.should == edit_admin_user_path(user.id)
       fill_in 'user_last_name', :with=>new_lastname
       select new_role, :from=>'user_role'
       click_button 'Update'

       # check the database and some items on the page
       page.should have_content(I18n.t('revs.messages.saved'))
       current_path.should == admin_users_path
       user.reload
       user.role.should == new_role
       user.last_name.should == new_lastname
       page.should have_content(new_lastname)
       
     end
         
   end
    
end
require "rails_helper"

describe("Admin Section",:type=>:request,:integration=>true) do
  
  before :each do
    logout
  end
  
  it "should allow an admin user to login and see the admin dashboard" do
      login_as(admin_login)
      expect(current_path).to eq(root_path)
      expect(page).to have_content('Admin Stanford')    # name at top of page  
      expect(page).to have_content('Signed in successfully.') # sign in message
      expect(page).to have_content('Admin') # admin menu on top of page
      expect(page).to have_content('Curator') # curator menu on top of page
    end

    it "should allow an admin user to return to the page they were on and then see the admin interface and curator interface" do
      starting_page=catalog_path('qb957rw1430')
      visit starting_page
      should_allow_flagging
      should_not_allow_annotations      
      login_as(admin_login)
      expect(current_path).to eq(starting_page)
      should_allow_flagging
      should_allow_annotations    
      should_allow_admin_section
      should_allow_curator_section
    end

    it "should not allow a non-admin user to see the admin dashboard" do 
      logout
      visit admin_dashboard_path
      expect(current_path).to eq(root_path)
    end

    describe "Administer collection highlights" do

      it "should not show the administer collection highlights page to a non-admin user" do
        logout
        visit admin_collection_highlights_path
        expect(current_path).to eq(root_path)
      end

      it "should show the administer collection highlights page to an admin user" do
        login_as(admin_login)
        visit admin_collection_highlights_path
        expect(current_path).to eq(admin_collection_highlights_path)
      end
      
    end
   
   describe "Administer users" do
   
     it "should not show the administer users page to a non-admin user" do
       logout
       visit admin_users_path
       expect(current_path).to eq(root_path)
     end
     
     it "should show all users, and be able to edit a user" do

       new_lastname='NewLastName'
       new_role='curator'
       
       # user role should be "user"
       user=User.find_by_username(user_login)
       expect(user.role).to eq('user')

       login_as(admin_login)
       visit admin_users_path
       ["#{user_login}","#{curator_login}","#{admin_login}"].each {|account| expect(page).to have_content(account)} # all accounts should be displayed
       expect(page).to have_content(user.full_name) # should show the current user's last name
       expect(page).not_to have_content(new_lastname) # show not show the new last name we are about to +enter+
       
       # let's edit them to make them a curator
       click_link "edit-#{user.id}"
       expect(current_path).to eq(edit_admin_user_path(user.id))
       fill_in 'user_last_name', :with=>new_lastname
       select new_role, :from=>'user_role'
       click_button 'Update'

       # check the database and some items on the page
       expect(page).to have_content(I18n.t('revs.messages.saved'))
       expect(current_path).to eq(admin_users_path)
       user.reload
       expect(user.role).to eq(new_role)
       expect(user.last_name).to eq(new_lastname)
       expect(page).to have_content(new_lastname)
       
     end
         
   end
    
end
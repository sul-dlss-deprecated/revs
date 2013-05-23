require 'spec_helper'

describe("Admin users",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
  
  it "should allow an admin user to login" do
      login_as(admin_login)
      current_path.should == root_path
      page.should have_content(admin_login)    # username at top of page  
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
    
end
require 'spec_helper'

describe("Curators",:type=>:request,:integration=>true) do
  
  before :each do
    logout
  end
  
  it "should allow a curator to login" do
      login_as(curator_login)
      current_path.should == root_path
      page.should have_content(curator_login)    # username at top of page  
      page.should have_content('Signed in successfully.') # sign in message
      page.should_not have_content('Admin') # no admin menu on top of page
      page.should have_content('Curator') # curator menu on top of page
    end

    it "should allow a curator to return to the page they were on and then see the curator interface, but not the admin interface" do
      starting_page=catalog_path('qb957rw1430')
      visit starting_page
      should_not_allow_flagging
      should_not_allow_annotations
      login_as(curator_login)
      current_path.should == starting_page
      should_allow_flagging
      should_allow_annotations    
      should_not_allow_admin_section
      should_allow_curator_section
    end
    
end
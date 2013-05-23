require 'spec_helper'

describe("Curator Section",:type=>:request,:integration=>true) do
  
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
    
    describe "Flagged Items List" do
    
      it "should show a list of flagged items and link to a page with flagged items" do
        login_as(curator_login)
        visit curator_tasks_path
        ["Record 1","Sebring 12 Hour, Green Park Straight, January 4"].each {|title| page.should have_content(title)}
        click_link 'Record 1'
        current_path.should == catalog_path('yt907db4998')
      end
      
    end
    
end
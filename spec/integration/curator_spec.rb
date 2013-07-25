require 'spec_helper'

describe("Curator Section",:type=>:request,:integration=>true) do
  
  before :each do
    logout
  end
  
  it "should allow a curator to login" do
      login_as(curator_login)
      current_path.should == root_path
      page.should have_content('Curator Revs')    # username at top of page  
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
      should_deny_access(admin_users_path)
      should_allow_curator_section
    end
    
    it "should allow a curator to view the bulk edit view" do

      login_as(curator_login)
      starting_page=search_path(:"f[pub_year_isim][]"=>"1955",:view=>"curator")
      visit starting_page
      current_path.should == search_path
      current_url.include?('view=curator').should be_true
            
    end

    it "should not allow a non-logged in or non curator user to view the bulk edit view" do

      starting_page=search_path(:"f[pub_year_isim][]"=>"1955",:view=>"curator")
      should_deny_access(starting_page)
      
      login_as(user_login)
      should_deny_access(starting_page)
      
    end
    
    describe "Flagged Items List" do
    
      it "should show a list of flagged items and link to a page with flagged items" do
        login_as(curator_login)
        visit curator_tasks_path
        ["Record 1","Sebring 12 Hour, Green Park..."].each {|title| page.should have_content(title)}
        click_link 'Record 1'
        current_path.should == catalog_path('yt907db4998')
      end
      
    end
    
end
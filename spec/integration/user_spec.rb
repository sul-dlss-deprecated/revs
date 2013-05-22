require 'spec_helper'

describe("User login and profile pages",:type=>:request,:integration=>true) do
  
  it "should allow an admin user to login" do
      admin_user='archivist1@example.com'
      login_as(admin_user)
      current_path.should == root_path
      page.should have_content(admin_user)    
      page.should have_content('Signed in successfully.')
      page.should have_content('Admin')
      page.should have_content('Curator')
    end
    
end
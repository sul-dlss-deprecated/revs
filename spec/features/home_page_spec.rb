require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do
  
    it "should render the home page with correct number of total images" do
      visit root_path
      page.should have_content("Collection 1")
      page.should have_content("The Revs Digital Library currently contains 16 items from 2 collections.")
      login_as(user_login)
      visit root_path
      page.should have_content("The Revs Digital Library currently contains 16 items from 2 collections.")
   end

    it "should render the home page with correct number of total images when a curator or admin is logged in" do
        logins=[curator_login,admin_login]
        logins.each do |user|
          login_as(user)
          visit root_path
          page.should have_content("Collection 1")
          page.should have_content("The Revs Digital Library currently contains 17 items from 2 collections. This total includes 1 hidden items.")
          logout
        end
    end
  
end
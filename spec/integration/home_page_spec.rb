require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do
  
    it "should render the home page with some text" do
        visit root_path
        page.should have_content("Collection 1")
        page.should have_content("The Revs Digital Library is built on top of the Stanford Digital Repository to provide a web based platform for discovery of automotive research and images.")
      end
  
end
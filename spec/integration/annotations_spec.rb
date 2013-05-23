require 'spec_helper'

describe("Annotation of images",:type=>:request,:integration=>true) do

  before :each do
    logout
    @starting_page=catalog_path('qb957rw1430')
  end

  it "should show the number of annotations in an image and allow logged in users to add a new one" do
    login_as(user_login)
    visit @starting_page
    should_allow_annotations    
    page.should have_content('(2 existing)')
  end
    
end
require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @collection1="David Nadig Collection"
    @collection2="John Dugdale Collection"
    @collection1_pid='kz071cg8658'
  end
    
  it "should show the first two collections on the collections page" do
    visit all_collections_path
    page.should have_content(@collection1)
    page.should have_content(@collection2)  
  end

  it "should show details of the first collection with an image" do
    visit catalog_path(@collection1_pid)
    page.should have_content(@collection1)
    page.should have_content("Collection Detail")  
    page.should have_content("David Nadig Collection")  
    page.should have_selector("img[alt$='Marlboro 12 Hour, August 12-14']")
  end
  
end
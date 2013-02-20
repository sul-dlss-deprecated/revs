require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @collection1="Marcus Chambers Collection"
    @collection2="John Dugdale Collection"
    @collection1_pid='wz243gf4151'
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
    page.should have_selector("img[alt$='Le Mans, 1955 ; Mille Miglia 1956  -  A REALLY long title with lots of characters in it to see how it looks. It also has some @daso odd char~!@ characters.']")
    page.should have_selector("img[alt$='Le Mans, 1955 ; Mille Miglia 1956']")
  end
  
end
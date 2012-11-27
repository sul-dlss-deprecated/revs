require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @collection1="Collection 1"
    @collection2="Le Mans Collection"
    @collection1_pid='nt028fd5773'
  end
  
  it "should show the first two collections on the collections page" do
    visit '/collections'
    page.should have_content(@collection1)
    page.should have_content(@collection2)  
  end

  it "should show details of the first collection with an image" do
    visit "/catalog/#{@collection1_pid}"
    page.should have_content(@collection1)
    page.should have_content("Collection Detail")  
    page.should have_selector("img[alt$='Record 1']")
    page.should have_selector("img[alt$='A Somewhat Longer Than Average Title']")
  end

  
end
require "rails_helper"

describe("Collection Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @collection1="David Nadig Collection"
    @collection2="John Dugdale Collection"
  end
    
  it "should show the first two collections on the collections page in both grid and detailed view" do
    [all_collections_path,all_collections_path(:view=>'detailed')].each do |url| 
      visit url
      expect(page).to have_content(@collection1)
      expect(page).to have_content(@collection2)  
    end
  end

  it "should show details of the first collection with an image, which is the highest priority image for that collection" do
    visit item_path(('kz071cg8658')
    expect(page).to have_content(@collection1)
    expect(page).to have_content("Collection Detail")  
    expect(page).to have_content("David Nadig Collection")  
    expect(page).to have_xpath("//img[contains(@src,\"https://stacks.stanford.edu/image/td830rb1584/2012-027NADI-1966-b1_2.0_0021_thumb\")]")
  end
    
end
require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
      
  it "should show a search result after searching for a title, starting at home page and executing a search" do
    visit root_path
    fill_in 'q', :with=>'Marlboro'
    click_button 'Search'
    page.should have_content('Results')
    page.should have_content('1 - 4 of 4')
    page.should have_content('Marlboro Governor\'s Cup, April 2-3')
    page.should have_xpath("//img[contains(@src, \"image/bg152pb0116/2012-027NADI-1966-b1_1.0_0013_thumb\")]")
    page.should have_content('black-and-white negatives')
  end

  it "should not show a search result after searching for a non existent string" do
    visit search_path(:q=>'bogus')
    page.should have_content('Results')
    page.should have_content('No entries found')
  end
  
  it "should immediately go to the item page if the search produces a single result" do
    visit search_path(:q=>'A Somewhat Shorter Than Average Title')
    current_path.should == item_path('qb957rw1430')
  end

  it "should show a search result after searching for a description" do
    visit search_path(:q=>'photo')
    page.should have_content('Results')
    page.should have_content('1 - 2 of 2')
    page.should have_content('The David Nadig Collection of the Revs Institute')
    page.should have_content('The John Dugdale Collection of the Revs Institute')
  end
  
  it "should show a facet search result for 1955" do
    visit search_path(:"f[pub_year_isim][]"=>'1955')
    page.should have_content('Results')
    page.should have_content('1 - 5 of 5')
    page.should have_content('Lime Rock Continental, September 1')
    page.should have_xpath("//img[contains(@src, \"image/dd482qk0417/2012-027NADI-1969-b4_12.2_0021_thumb\")]")
    page.should have_content('black-and-white negatives')
  end
  
end
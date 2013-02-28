require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
  
  before(:each) do
    @collection1="David Nadig Collection"
    @collection2="John Dugdale Collection"
  end
    
  it "should show the first two collections on the collections page" do
    visit all_collections_path
    page.should have_content(@collection1)
    page.should have_content(@collection2)  
  end

  it "should show details of the first collection with an image" do
    visit catalog_path('kz071cg8658')
    page.should have_content(@collection1)
    page.should have_content("Collection Detail")  
    page.should have_content("David Nadig Collection")  
    page.should have_selector("img[alt$='Marlboro 12 Hour, August 12-14']")
  end

  it "should show an item detail page with image and linked facet metadata" do 
    visit catalog_path('yt907db4998')
    page.should have_content('Record 1')
    page.should have_content('2011-023DUG-3.0_0017')
    page.should have_content('slides')
    page.should have_content('1960')
    page.should have_content('John Dugdale Collection')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/yt907db4998/2011-023DUG-3.0_0017_thumb']")
    page.should have_xpath("//a/@href['/catalog?f%5Bformat_ssim%5D%5B%5D=slides']")
    page.should have_xpath("//a/@href['catalog?f%5Bcollection_ssim%5D%5B%5D=John+Dugdale+Collection']")
    page.should have_xpath("//a/@href['/catalog?f%5Bpub_year_isim%5D%5B%5D=1960']")
    page.should have_content('Other items in John Dugdale Collection (2)')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/qb957rw1430/2011-023DUG-3.0_0015_square']")
  end
  
  it "should show a search result after searching for a title" do
    visit search_path(:q=>'Marlboro')
    page.should have_content('Results')
    page.should have_content('1 - 4 of 4')
    page.should have_content('Marlboro 12 Hour, August 12-14')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/yh093pt9555/2012-027NADI-1966-b1_6.4_0011_thumb']")
    page.should have_content('black-and-white negatives')
  end
  
  it "should show a facet search result for 1955" do
    visit search_path(:"f[pub_year_isim][]"=>'1955')
    page.should have_content('Results')
    page.should have_content('1 - 5 of 5')
    page.should have_content('Lime Rock Continental, September 1')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/dd482qk0417/2012-027NADI-1969-b4_12.2_0021_thumb']")
    page.should have_content('black-and-white negatives')
  end
    
end
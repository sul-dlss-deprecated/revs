require 'spec_helper'

describe("Item Pages",:type=>:request,:integration=>true) do

  it "should show an item detail page with image and linked facet metadata with no description" do 
    visit catalog_path('yt907db4998')
    page.should have_content('Record 1')
    page.should have_content('2011-023DUG-3.0_0017')
    page.should have_content('slides')
    page.should have_content('1960')
    page.should have_content('John Dugdale Collection')
    page.should_not have_content('Description:')    
    page.should have_xpath("//img[contains(@src, \"image/yt907db4998/2011-023DUG-3.0_0017_thumb\")]")
    page.should have_xpath("//a[contains(@href, \"/catalog?f%5Bformat_ssim%5D%5B%5D=slides\")]")    
    page.should have_xpath("//a[contains(@href, \"/catalog?f%5Bcollection_ssim%5D%5B%5D=John+Dugdale+Collection\")]")    
    page.should have_xpath("//a[contains(@href, \"/catalog?f%5Bpub_year_isim%5D%5B%5D=1960\")]")    
    page.should have_xpath("//img[contains(@src, \"image/qb957rw1430/2011-023DUG-3.0_0015_square\")]")
  end

  it "should show an item detail page that has a description" do 
    visit catalog_path('yh093pt9555')
    page.should have_content('Marlboro 12 Hour, August 12-14')
    page.should have_content('Description:')    
    page.should have_content('This is the description of this image')
    page.should have_xpath("//img[contains(@src, \"image/yh093pt9555/2012-027NADI-1966-b1_6.4_0011\")]")
  end

end
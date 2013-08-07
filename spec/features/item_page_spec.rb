require 'spec_helper'

describe("Item Pages",:type=>:request,:integration=>true) do

  it "should show the default Untitled value for the title when its not in the solr document" do
    visit catalog_path('jg267fg4283')
    find('.show-document-title').should have_content('Untitled')
  end
  
  it "should show an item detail page with image and linked facet metadata with no description" do 
    visit catalog_path('yt907db4998')
    find('.show-document-title').should have_content('Record 1')
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
    find('.show-document-title').should have_content('Marlboro 12 Hour, August 12-14')
    page.should have_content('Description:')    
    page.should have_content('This is the description of this image')
    page.should have_content('Year:')
    page.should have_content('1955')
    page.should have_content('Collection:')
    page.should have_content('David Nadig Collection')
    page.should have_xpath("//img[contains(@src, \"image/yh093pt9555/2012-027NADI-1966-b1_6.4_0011\")]")
  end

  it "should show an item detail page metadata section only if values exist for metadata in that section" do
    visit catalog_path('yh093pt9555') # Item with Vehicle and Race field values
    find('.show-document-title').should have_content('Marlboro 12 Hour, August 12-14')
    page.should have_content('Vehicle Information')
    page.should have_content('Marque:')
    page.should have_content('Ford, Chevrolet')
    page.should have_content('Model:')
    page.should have_content('Camaro, Mustang, Camaro')
    page.should have_content('Model Year:')
    page.should have_content('1950, 1951')
    page.should have_content('Vehicle Markings:')
    page.should have_content('Oil on hood')
    page.should have_content('Race Information')
    page.should have_content('Event:')
    page.should have_content('Indy Race')
    page.should have_content('Venue:')
    page.should have_content('Indy 500 Speedway')
    page.should have_content('Race Data:')
    page.should have_content('This is who won, who lost, other bits about the race.')
    visit catalog_path('xf058ys1313') # Item without Vehicle and Race field values
    page.should have_content('Thompson Raceway, May 2')
    page.should_not have_content('Vehicle Information')
    page.should_not have_content('Race Information')
  end

end

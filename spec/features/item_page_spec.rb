require "rails_helper"

describe("Item Pages",:type=>:request,:integration=>true) do

  it "should show the default Untitled value for the title when its not in the solr document" do
    visit catalog_path('jg267fg4283')
    expect(find('.show-document-title')).to have_content('Untitled')
  end
  
  it "should show an item detail page with image and linked facet metadata with no description" do 
    visit catalog_path('yt907db4998')
    expect(find('.show-document-title')).to have_content('Record 1')
    expect(page).to have_content('2011-023DUG-3.0_0017')
    expect(page).to have_content('slides')
    expect(page).to have_content('1960')
    expect(page).to have_content('John Dugdale Collection')
    expect(page).not_to have_content('Description:')    
    expect(page).to have_xpath("//img[contains(@src, \"image/yt907db4998/2011-023DUG-3.0_0017_thumb\")]")
    expect(page).to have_xpath("//a[contains(@href, \"/catalog?f%5Bformat_ssim%5D%5B%5D=slides\")]")    
    expect(page).to have_xpath("//a[contains(@href, \"/catalog?f%5Bcollection_ssim%5D%5B%5D=John+Dugdale+Collection\")]")    
    expect(page).to have_xpath("//a[contains(@href, \"/catalog?range%5Bpub_year_isim%5D%5Bbegin%5D=1960&range%5Bpub_year_isim%5D%5Bend%5D=1960\")]")    
    expect(page).to have_content("John Dugdale Collection (2)")
    expect(page).to have_content("View all collection items")
  end

  it "should show the item page with a request to /druid" do
    visit "/yh093pt9555"
    expect(find('.show-document-title')).to have_content('Marlboro 12 Hour, August 12-14')
  end

  it "should show an item detail page that has a description" do 
    visit catalog_path('yh093pt9555')
    expect(find('.show-document-title')).to have_content('Marlboro 12 Hour, August 12-14')
    expect(page).to have_content('Description:')    
    expect(page).to have_content('This is the description of this image')
    expect(page).to have_content('Year:')
    expect(page).to have_content('1955')
    expect(page).to have_content('Collection:')
    expect(page).to have_content('David Nadig Collection')
    expect(page).to have_xpath("//img[contains(@src, \"image/yh093pt9555/2012-027NADI-1966-b1_6.4_0011\")]")
  end

  it "should show a 404 error message when you visit an invalid ID" do 
    visit catalog_path('yh093pt9554')
    expect(current_path).to eq(catalog_path('yh093pt9554'))
    expect(page).to have_content(I18n.t('revs.errors.404_message'))
    expect(page.status_code).to eq(404)
  end

  it "should show an item detail page metadata section only if values exist for metadata in that section" do
    visit catalog_path('yh093pt9555') # Item with Vehicle and Race field values
    expect(find('.show-document-title')).to have_content('Marlboro 12 Hour, August 12-14')
    expect(page).to have_content('Vehicle Information')
    expect(page).to have_content('Marque:')
    expect(page).to have_content('Ford, Chevrolet')
    expect(page).to have_content('Model:')
    expect(page).to have_content('Camaro, Mustang, Camaro')
    expect(page).to have_content('Model Year:')
    expect(page).to have_content('1950, 1951')
    expect(page).to have_content('Vehicle Markings:')
    expect(page).to have_content('Oil on hood')
    expect(page).to have_content('Race Information')
    expect(page).to have_content('Event:')
    expect(page).to have_content('Indy Race')
    expect(page).to have_content('Venue:')
    expect(page).to have_content('Indy 500 Speedway')
    expect(page).to have_content('Race Data:')
    expect(page).to have_content('This is who won, who lost, other bits about the race.')
    visit catalog_path('xf058ys1313') # Item without Vehicle and Race field values
    expect(page).to have_content('Thompson Raceway, May 2')
    expect(page).not_to have_content('Vehicle Information')
    expect(page).not_to have_content('Race Information')
  end

end

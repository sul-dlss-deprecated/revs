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
  
  it "should allow case insensitive searches within text fields" do
    copy_fields_to_check = [:marque, :vehicle_model, :people, :entrant, :current_owner, :venue, :track, :event, :city, :country, :state, :city_section, :photographer]
    #model_year
    fields = {}
    counter = 0
    strings = array_of_unique_strings(copy_fields_to_check.size*2) #Go double here so we can test "Random1 Random2 in the text field"
    first_druid = 'dd482qk0417'
    second_druid = 'yt907db4998'
    
    #Set up a unique string to use for all the above
    #Also ensure that they map to a Solr Field
    copy_fields_to_check.each do |field|
      SolrDocument.field_mappings[field].should_not be_nil #If sometime was typed wrong in copy_fields_to_check this will catch it
      #Set up the key we'll be using for this
      fields[field] = strings[counter] + " " + strings[counter+1]
      counter += 2 
    end
    login_as(curator_login)
    
    #Test each field with search results
    fields.keys.each do |field|
      #1.  A query for the strings assigned to this field should return no results
      searches_no_result(fields[field])
      
      #2.  Assign this query to one druid, should go directly to that druid
      update_solr_field(first_druid, field, fields[field])
      searches_direct_route(fields[field], first_druid)
      
      #3.  Assign this query to a second druid, we should get multiple results now
      update_solr_field(second_druid, field, fields[field])
      searches_multiple_results(fields[field],2)
      
    end
   
  
  end 

  
end
require "rails_helper"

describe("Search Pages",:type=>:request,:integration=>true) do

  it "should show a search result after searching for a title, starting at home page and executing a search" do
    visit root_path
    fill_in 'q', :with=>'Marlboro'
    click_button 'Search'
    expect(page).to have_content('Results')
    expect(page).to have_content('1 - 4 of 4')
    expect(page).to have_content('Marlboro Governor\'s Cup, April 2-3')
    expect(page).to have_xpath("//img[contains(@src, \"image/bg152pb0116/2012-027NADI-1966-b1_1.0_0013_thumb\")]")
  end

  it "should not reset the search when faceting after entering a search term" do
    visit root_path
    click_link 'Revs Institute® Archives'
    expect(page).to have_content('1 - 10 of 17')
    fill_in 'q', :with=>'Ford'
    click_button 'Search'
    expect(page).to have_content('Results')
    expect(page).to have_content('1 - 2 of 2')
    expect(page).to have_content('Sebring 12 Hour, Green Park Straight, January 4')
    expect(page).to have_content('David Nadig Collection')
  end

  it "should not show a search result after searching for a non existent string" do
    visit search_path(:q=>'bogus')
    expect(page).to have_content('Results')
    expect(page).to have_content('No entries found')
  end

  it "should immediately go to the item page if the search produces a single result" do
    visit search_path(:q=>'A Somewhat Shorter Than Average Title')
    expect(current_path).to eq(item_path('qb957rw1430'))
  end

  it "should show a search result after searching for a description" do
    visit search_path(:q=>'photo')
    expect(page).to have_content('Results')
    expect(page).to have_content('1 - 2 of 2')
    expect(page).to have_content('The David Nadig Collection of The Revs Institute')
    expect(page).to have_content('The John Dugdale Collection of The Revs Institute')
  end

  it "should show 2 results for both chevy and chevrolet due to synonym matching" do
    search_strings=['chevy','chevrolet','Chevy','Chevrolet']
    search_strings.each do |search|
      visit search_path(:q=>search)
      expect(page).to have_content('Results')
      expect(page).to have_content('1 - 2 of 2')
      expect(page).to have_content('Lime Rock Continental, September 1')
      expect(page).to have_content('Marlboro 12 Hour, August 12-14')
    end
  end

  it "should find matches for gt-350, gt350 and gt 350 due to tokenization setup when doing an exact search" do
    search_strings=['gt 350','gt-350','gt350']
    search_strings.each do |search|
      visit search_path(:q=>search,:search_match=>'exact')
      expect(page).to have_content('Results')
      expect(page).to have_content('1 - 3 of 3')
      expect(page).to have_content('Thompson Raceway, May 2')
      expect(page).to have_content('Record 1')
      expect(page).to have_content('Lime Rock Continental, September 1')
    end
  end

  it "should find different matches for gt-350 and gt 350 based on exact match or not", pending: true do
    visit search_path(:q=>'gt 350')
    expect(page).to have_content('Results')
    expect(page).to have_content('1 - 2 of 2')
    visit search_path(:q=>'gt 350',:search_match=>'exact')
    expect(page).to have_content('1 - 3 of 3')
  end

  it "should show a facet search result for 1955" do
    search_params=[{:"f[pub_year_isim][]"=>'1955'}]
    search_params.each do |search_param|
      visit search_path(search_param)
      expect(page).to have_content('Results')
      expect(page).to have_content('1 - 5 of 5')
      expect(page).to have_content('Lime Rock Continental, September 1')
      expect(page).to have_xpath("//img[contains(@src, \"image/dd482qk0417/2012-027NADI-1969-b4_12.2_0021_thumb\")]")
      expect(page).to have_content('1955')
    end
  end

  it "should show return a 404 if you set the end year before the begin year in the querystring or set bogus values" do
    visit search_path(:"range[pub_year_isim][begin]"=>'1955',:"range[pub_year_isim][end]"=>'1954')
    expect(page).to have_content(I18n.t('revs.errors.sorry'))
    expect(page.status_code).to be(404)
  end

  it "should allow case insensitive searches within text fields" do
    copy_fields_to_check = [:marque, :vehicle_model, :people, :entrant, :current_owner, :venue, :track, :event, :city, :country, :state, :city_section, :photographer]
    #model_year
    fields = {}
    counter = 0
    strings = array_of_unique_strings(copy_fields_to_check.size*2) #Go double here so we can test "Random1 Random2 in the text field"
    first_druid = 'dd482qk0417'
    second_druid = 'yt907db4998'
    random_complex_check = rand(0...copy_fields_to_check.size) #Since complex searches for everyone takes awhile, only run this for one random one each time


    #Set up a unique string to use for all the above
    #Also ensure that they map to a Solr Field
    copy_fields_to_check.each do |field|
      expect(SolrDocument.field_mappings[field]).not_to be_nil #If sometime was typed wrong in copy_fields_to_check this will catch it
      #Set up the key we'll be using for this
      fields[field] = strings[counter] + " " + strings[counter+1]
      counter += 2
    end
    login_as(curator_login)

    #Test each field with search results
    fields.keys.each do |field|
      complex = false
      complex = true if copy_fields_to_check[random_complex_check] == field

      #1.  A query for the strings assigned to this field should return no results
      searches_no_result(fields[field], complex)

      #2.  Assign this query to one druid, a search should go directly to that druid
      update_solr_field(first_druid, field, fields[field])
      searches_direct_route(fields[field], first_druid, complex)

      #3.  Assign this query to a second druid, we should get multiple results now
      update_solr_field(second_druid, field, fields[field])
      searches_multiple_results(fields[field],2, complex)

    end
    reindex_solr_docs([first_druid, second_druid]) #Clean up the druids

  end

  #This is seperate from the test above due to special restrictions on the field
  it "the model_year_tim copyfield should allow text searching of the model_year_ssim field" do
    first_druid = 'dd482qk0417'
    second_druid = 'yt907db4998'
    year = "1851"

    #1.  A query for the year here should return no results
    searches_no_result(year, false)

    #2. Assign the year to one druid, a search should go directly to that druid
    update_solr_field(first_druid, :model_year, year)
    searches_direct_route(year, first_druid, false)

    #3. Assign the year to two druids, a search should now return two results
    update_solr_field(second_druid, :model_year, year)
    searches_multiple_results(year,2, false)

    reindex_solr_docs([first_druid, second_druid]) #Clean up the druids

  end


end

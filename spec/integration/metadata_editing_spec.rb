require 'spec_helper'

describe("Metadata Editing",:type=>:request,:integration=>true) do
  
  before :each do
    logout
  end
    
  def bulk_edit_interface_shown_should_be_shown(visible)
    visit root_path
    click_link '1966' # a facet link
    page.should have_content('Results')
    page.should have_content('1 - 6 of 6')
    page.should have_link('Detailed')
    page.should have_link('Gallery')
    visible == true ? page.should(have_link('Curator')) : page.should_not(have_link('Curator'))
  end
  
  it "should not show editing interface to non-logged in users or non-curator users, but show it for admin and curators" do
      
      bulk_edit_interface_shown_should_be_shown(false)            
      
      login_as(user_login)
      bulk_edit_interface_shown_should_be_shown(false)            
      logout

      login_as(admin_login)
      bulk_edit_interface_shown_should_be_shown(true)            
      logout

      login_as(curator_login)
      bulk_edit_interface_shown_should_be_shown(true)            
      logout

  end

  it "should show error messages when the curator doesn't enter in all required information to perform a bulk edit" do

      druids_to_edit=%w{nn572km4370 kn529wc4372}
      new_value='newbie!'
      field_to_edit='Title'
      old_values={}

      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        doc.title.should_not == new_value
        old_values[druid] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
        Editstore::Change.where(:new_value=>new_value,:old_value=>doc.title,:druid=>druid).size.should == 0
      end
            
      logout
      login_as(curator_login)

      visit root_path
      click_link '1966' # a facet link
      click_link 'Curator' # enter bulk editing inteface
      page.should_not have_content new_value # the new title should not be on the page yet

      fill_in 'bulk_edit_new_value', :with=>new_value
      select field_to_edit, :from=>'bulk_edit_field_name' # be sure title field is selected
      click_button 'Update' # try and perform an update without entering a new value
      page.should have_content 'To apply a bulk update, select the field to update, enter a new value and select some items.' # oops, didn't work since we didn't select anything

      # TODO, we should then be able to check all of the druids and resubmit the form to confirm the changes went through, but I am unable to get capybara to correctly submit the checkbox selection

      # druids_to_edit.each {|druid| check "bulk_edit_selected_druids_#{druid}"} # select some druids      # 
      # click_button 'Update' # now perform the update
      # 
      # page.should have_content 'Your update has been applied to all the items you selected.' # it worked!
      # page.should have_content new_value # the new title entered should be on the page
      # 
      # # confirm new field has been updated in solr and has correct rows in editstore database
      # druids_to_edit.each do |druid|
      #   doc=SolrDocument.find(druid)
      #   doc.title.should == new_value
      #   Editstore::Change.where(:new_value=>new_value,:old_value=>old_values[druid],:druid=>druid).size.should == 1
      # end
            
  end
  
end
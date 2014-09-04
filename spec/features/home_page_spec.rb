require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do

    it "should render the home page with correct featured sections" do
      visit root_path
      expect(page).to have_content I18n.t('revs.user_galleries.heading_featured')
      expect(page).to have_content I18n.t('revs.nav.more_galleries')
      expect(page).to have_content I18n.t('revs.nav.more_to_explore')
   end

    it "should give a nice error message page if we visit a bogus url" do
      visit "/bogusness"
      expect(current_path).to eq("/bogusness")
      expect(page).to have_content I18n.t('revs.errors.sorry')
      expect(page).to have_content I18n.t('revs.errors.404_message')
      expect(page).to have_xpath("//a[contains(@href, \"/\")]")
      expect(page).to have_xpath("//a[contains(@href, \"/collection\")]")
      expect(page).to have_xpath("//a[contains(@href, \"/contact\")]")
    end

end

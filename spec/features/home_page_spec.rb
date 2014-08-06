require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do

    it "should render the home page with correct featured sections" do
      visit root_path
      page.should have_content I18n.t('revs.user_galleries.heading_featured')
      page.should have_content I18n.t('revs.nav.more_galleries')
      page.should have_content I18n.t('revs.nav.more_to_explore')
   end

    it "should give a nice error message page if we visit a bogus url" do
      visit "/bogusness"
      current_path.should == "/bogusness"
      page.should have_content I18n.t('revs.errors.sorry')
      page.should have_content I18n.t('revs.errors.404_message')
      page.should have_xpath("//a[contains(@href, \"/\")]")
      page.should have_xpath("//a[contains(@href, \"/collection\")]")
      page.should have_xpath("//a[contains(@href, \"/contact\")]")
    end

end

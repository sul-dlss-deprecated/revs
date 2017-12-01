require "rails_helper"

describe("Home Page",:type=>:request,:integration=>true) do

  context "more to explore and featured galleries enabled" do

    before :each do
      Revs::Application.config.disable_more_to_explore = false
      Revs::Application.config.disable_featured_galleries = false
    end

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

      it "should show a link to the saved queries if they exist" do
        visit root_path
        expect(page).to have_content I18n.t('revs.nav.saved_queries_home_page_overview')
        expect(page).to_not have_content I18n.t('revs.nav.video_tutorials')
      end

      it "should not show a link to the saved queries if there are none, and should show video tutorials instead" do
        SavedQuery.where(:active=>true).where(:visibility=>'public').each {|s| s.update_attributes(:active=>false)}
        visit root_path
        expect(page).to_not have_content I18n.t('revs.nav.saved_queries_home_page_overview')
        #expect(page).to have_content I18n.t('revs.nav.video_tutorials')
      end
    end

    context "more to explore and featured galleries disabled" do

      before :each do
        Revs::Application.config.disable_more_to_explore = true
        Revs::Application.config.disable_featured_galleries = true
      end

        it "should render the home page without featured sections" do
          visit root_path
          expect(page).to_not have_content I18n.t('revs.user_galleries.heading_featured')
          expect(page).to_not have_content I18n.t('revs.nav.more_galleries')
          expect(page).to_not have_content I18n.t('revs.nav.more_to_explore')
       end

        it "should show a link to the saved queries if they exist" do
          visit root_path
          expect(page).to_not have_content I18n.t('revs.nav.saved_queries_home_page_overview')
          expect(page).to_not have_content I18n.t('revs.nav.video_tutorials')
        end

        it "should not show a link to the saved queries if there are none, and should show video tutorials instead" do
          SavedQuery.where(:active=>true).where(:visibility=>'public').each {|s| s.update_attributes(:active=>false)}
          visit root_path
          expect(page).to_not have_content I18n.t('revs.nav.saved_queries_home_page_overview')
          expect(page).to_not have_content I18n.t('revs.nav.video_tutorials')
        end
      end

end

require "rails_helper"

describe("Curator Section",:type=>:request,:integration=>true) do

  before :each do
    logout
    @comment_field='flag_comment'
    @flag_button=I18n.t('revs.flags.flag')
  end


  it "should allow a curator to login and show metadata facet" do
      login_as(curator_login)
      expect(current_path).to eq(root_path)
      expect(page).to have_content('Curator Revs')    # username at top of page
      expect(page).to have_content('Signed in successfully.') # sign in message
      expect(page).not_to have_content('Admin') # no admin menu on top of page
      expect(page).to have_content('Curator') # curator menu on top of page
      expect(page).to have_content('More Metadata') # curator more metadata facet
    end

    it "should NOT show more metadata facet to non-curators" do
      visit root_path
      expect(page).not_to have_content('More Metadata') # curator more metadata facet is not shown
    end

    it "should allow a curator to return to the page they were on and then see the curator interface, but not the admin interface" do
      starting_page=item_path(('qb957rw1430')
      visit starting_page
      should_allow_flagging
      should_not_allow_annotations
      login_as(curator_login)
      expect(current_path).to eq(starting_page)
      should_allow_flagging
      should_allow_annotations
      should_deny_access(admin_users_path)
      should_allow_curator_section
    end

    it "should allow a curator to view the bulk edit view" do
      login_as(curator_login)
      starting_page=search_path(:"f[pub_year_isim][]"=>"1955",:view=>"curator")
      visit starting_page
      expect(current_path).to eq(search_path)
      expect(current_url.include?('view=curator')).to be_truthy
    end

    it "should not allow a non-logged in or non curator user to view the bulk edit view" do
      starting_page=search_path(:"f[pub_year_isim][]"=>"1955",:view=>"curator")
      should_deny_access(starting_page)
      login_as(user_login)
      should_deny_access(starting_page)
    end

    it "should not allow a non-logged in or non curator user to view the item edit reports" do
      starting_page=edits_table_curator_tasks_path
      should_deny_access(starting_page)
      login_as(user_login)
      should_deny_access(starting_page)
    end

    it "should allow a curator to view edited item history on an item page" do
      login_as(curator_login)
      visit item_path(('qb957rw1430')
      expect(page).to have_content 'metadata edit history'
      expect(page).to have_content 'May 8, 2013 5:00 PM by Curator Revs'
      expect(page).to have_content 'April 5, 2013 5:00 PM by admin1'
      expect(page).to have_content 'January 4, 2013 4:00 PM by Curator Revs'
    end

    it "should now allow a non-curator to view edited item history on an item page" do
      logout
      visit item_path(('qb957rw1430')
      expect(page).not_to have_content 'Metadata Edit History'
      expect(page).not_to have_content 'May 8, 2013 by Curator Revs'
    end

    it "should not show item edit history to curators if none exists for an item" do
      login_as(curator_login)
      visit item_path(('yh093pt9555')
      expect(page).not_to have_content 'Metadata Edit History'
    end

    it "should allow a curator to view the item edit reports" do
      login_as(curator_login)
      visit edits_table_curator_tasks_path
      expect(current_path).to eq(edits_table_curator_tasks_path)
      edited_users=["Curator Revs 4","admin1 1"]
      edited_users.each {|title| expect(page).to have_content(title)}
      expect(page).to have_content 'By Item'
      expect(page).to have_content 'By User'
    end

    describe "Flagged Items List" do

      it "should show a list of flagged items and link to a page with flagged items" do
        login_as(curator_login)
        visit curator_tasks_path
        ["Record 1","Sebring 12 Hour, Green Park Straight, January 4"].each {|title| expect(page).to have_content(title)}
        within ('#flags_table table') do
          click_link 'Record 1'
        end
        expect(current_path).to eq(item_path('yt907db4998'))
      end

      it "Should show a submit button to refresh list of all open flags by flag state" do
        login_as(curator_login)
        visit curator_tasks_path
        expect(page).to have_button I18n.t('revs.nav.submit')
      end

      it "The submit button should refresh the list of all open flags" do
        druid = "dd482qk0417"
        message = "Sample Flag To Test Refresh"
        login_as(curator_login)
        visit curator_tasks_path
        #Make sure the flag is not there
        expect(page).to have_no_content message

        #Add it
        login_and_add_a_flag(curator_login, druid, message)

        #Return to the page and make sure it is there
        visit curator_tasks_path
        expect(page).to have_content message

        #Delete the last flag
        Flag.last.delete

        first(:button, I18n.t('revs.nav.submit')).click
        expect(page).to have_no_content message
      end



    end

end

require "rails_helper"

describe("Flagging",:type=>:request,:integration=>true) do

  before :each do
    logout
    @remove_button=I18n.t('revs.actions.remove')
    @update_button=I18n.t('revs.nav.update_completely')
    @review_button=I18n.t('revs.flags.in_review')
    @flag_button=I18n.t('revs.flags.flag')
    @comment_field='flag_comment'
    @resolution_field = 'flag_resolution'
    @default_flag_type='error'
    @wont_fix_button=I18n.t('revs.flags.wont_fix')
    @fix_button=I18n.t('revs.flags.fixed')
    @ask_to_notify_checkbox=I18n.t('revs.flags.notify_me')
    RevsMailer.stub_chain(:flag_resolved,:deliver).and_return('a mailer')
  end

  it "should show the flagging link to non-logged in users even if there are no flags" do

    visit catalog_path('xf058ys1313')
    should_allow_flagging

  end

  it "should allow a non-logged in user to create up to the maximum number of anonymous flag for an object but no more; and should not show the anonymous flags" do

    druid='sc411ff4198'
    visit catalog_path(druid)
    expect(page).not_to have_css('#flag-details-link.hidden')
    should_allow_flagging
    expect(page).not_to have_content(@ask_to_notify_checkbox) # non-logged in users cannot be notified when flag is resolved

    expect(Flag.where(:druid=>druid).count).to eq(1) # one existing flag (from fixtures)

    #Add comments up to the limit
    flags = 0
    while flags < Revs::Application.config.num_flags_per_item_per_user do
      flag_text="comment #{flags}"
      create_flag(flag_text)
      flags += 1
      expect(page).not_to have_content(flag_text)
    end

    total_flags=Revs::Application.config.num_flags_per_item_per_user+1
    expect(Flag.where(:druid=>druid).where('user_id is null').count).to eq(Revs::Application.config.num_flags_per_item_per_user) # we now have the maximum number of anonymous flags
    expect(Flag.where(:druid=>druid).count).to eq(total_flags) # the existing one, plus all the onew ones
    should_not_allow_flagging
    expect(find(".num-flags-badge")).to have_content(total_flags)
    expect(page).to have_content('user comment') # the non-anonymous flag text

  end

  it "should allow non-logged in users to view flags for items that have them" do

    visit catalog_path('sc411ff4198')
    expect(page).not_to have_css('#flag-details-link.hidden')
    should_allow_flagging
    expect(page).to have_content("user comment") # the text of the flag
    expect(find(".num-flags-badge")).to have_content("1")

  end

  it "should hide flags for a disabled user account" do

    # deactivate a user so their flags are hidden
    disable_user(user_login)

    visit catalog_path('sc411ff4198')
    should_allow_flagging
    expect(page).not_to have_content("user comment") # the text of the flag is not there
    expect(find(".num-flags-badge")).to have_content("0")

  end

  it "should allow logged in users to view flags, even those created by anonynous users" do

    druid='sc411ff4198'
    visit catalog_path(druid)
    anon_comment="anonymous comment"
    create_flag(anon_comment)
    expect(page).not_to have_content(anon_comment) # the text of the anonymous flag is not visible yet

    login_as_user_and_goto_druid(user_login,druid)

    expect(find('.flag-details')).to be_visible
    should_allow_flagging
    expect(page).to have_content("user comment") # the text of the existing fixture user flag
    expect(page).to have_content(anon_comment) # the text of the anonymous flag

    expect(find(".num-flags-badge")).to have_content("2")

  end

  it "should allow a logged in user to request to be notified when their flag is resolved" do
    druid='qb957rw1430'
    user_comment='all wrong!'
    curator_comment='righto old chap'
    initial_flag_count=Flag.count
    # login and visit an item as a regular user
    login_as_user_and_goto_druid(user_login,druid)
    check 'flag_notify_me'
    create_flag(user_comment)
    # check the database
    user=User.find_by_username(user_login)
    expect(Flag.count).to eq(initial_flag_count + 1)
    flag=Flag.last
    expect(flag.comment).to eq(user_comment)
    expect(flag.flag_type).to eq(@default_flag_type)
    expect(flag.user).to eq(user)
    expect(flag.notify_me).to be_truthy
    expect(flag.notification_state).to eq('pending')

    flag_id = check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

    # notification should go out
    expect(RevsMailer).to receive(:flag_resolved)

    #Login As a Curator and Mark It As Fixed
    resolve_flag_fix(curator_login, druid, user_comment, curator_comment, flag_id)

    #Ensure the Flag Was Resolved via a message on the page to the user and in the database
    check_flag_was_marked_fix(user_comment, initial_flag_count+1, curator_comment, flag_id)

  end

  it "should allow multiple logged in users to flag an item, show all flags, and then allow the user remove their own flag" do

      druid='qb957rw1430'
      user_comment='all wrong!'

      initial_flag_count=Flag.count

      # login and visit an item as a regular user
      login_as_user_and_goto_druid(user_login,druid)
      #flag the item
      expect(page).to have_content(@ask_to_notify_checkbox) # logged in users can ask to be notified when flag is resolved
      create_flag(user_comment)

      # check the page for the correct messages
      expect(current_path).to eq(catalog_path(druid))
      expect(page).to have_content(I18n.t('revs.flags.created'))
      expect(page).to have_content(user_comment)
      expect(page).to have_button(@remove_button)

      # check the database
      user=User.find_by_username(user_login)
      expect(Flag.count).to eq(initial_flag_count + 1)
      flag=Flag.last
      expect(flag.comment).to eq(user_comment)
      expect(flag.flag_type).to eq(@default_flag_type)
      expect(flag.user).to eq(user)
      expect(flag.notify_me).to be_falsey
      expect(flag.notification_state).to be_nil

      # login and visit an item as a curator
      logout
      login_as(curator_login)
      curator_comment='not so bad'

      #flag the item
      visit catalog_path(druid)
      create_flag(curator_comment)

      # check the page for the correct messages
      expect(current_path).to eq(catalog_path(druid))
      expect(page).to have_content(I18n.t('revs.flags.created'))
      expect(page).to have_content(curator_comment)
      expect(page).to have_content(user_comment)
      expect(page).to have_button(@remove_button)

      # check the database
      curator=User.find_by_username(curator_login)
      expect(Flag.count).to eq(initial_flag_count + 2)
      flag=Flag.last
      expect(flag.comment).to eq(curator_comment)
      expect(flag.flag_type).to eq(@default_flag_type)
      expect(flag.user).to eq(curator)

      # remove and confirm deletion of the curator's flag in the database
      #Since curators can remove any comment now, we need to target the removal of the comment that the curator just added
      remove_flag(curator_login, druid, curator_comment)

      expect(page).to have_content(I18n.t('revs.flags.removed'))
      expect(Flag.count).to eq(initial_flag_count + 1)
      expect(Flag.last.user).to eq(user)
    end

    it "should allow curators to delete flags set by any other user in the system and increase that user's spam count" do

      #Vars
      druid='qb957rw1430'
      user_comment='all wrong!'
      starting_spam_count = get_user_spam_count(user_login)
      initial_flag_count=Flag.count

      #Login as a User and Leave A comment
      login_and_add_a_flag(user_login, druid, user_comment)

      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

      #Login as an admin and delete the flag
      remove_flag(curator_login, druid, user_comment)

      #Ensure The Flag Was Deleted On the Page and Database
      check_flag_was_deleted(user_login, druid, initial_flag_count)

      #Ensure the User Was Penalized for Spam
      expect(get_user_spam_count(user_login)).to eq(starting_spam_count+1)

    end

    it "should allow curators to move a flag to the review state" do

      #Vars
      druid='qb957rw1430'
      user_comment='something to be reviewed'
      initial_flag_count=Flag.count

      #Login as a User and Leave A comment
      login_and_add_a_flag(user_login, druid, user_comment)

      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

      #Login As a Curator and set the flag to review
      review_flag(curator_login, druid, user_comment)

      #Ensure The Flag Was Set to review state
      expect(Flag.last.state).to eq Flag.review

    end

    it "should update an item with the flag comment description when asked in curator reports" do

      #Vars
      druid='qb957rw1430'
      user_comment='something to be reviewed'
      initial_flag_count=Flag.count
      s=SolrDocument.find(druid)
      expect(s.description.blank?).to be_truthy

      #Login as a User and Leave A comment
      login_and_add_a_flag(user_login, druid, user_comment)

      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)
      flag=Flag.last
      expect(flag.state).to eq Flag.open

      logout
      login_as(curator_login)

      #go to curator report, select flag and click update button
      visit flags_table_curator_tasks_path
      check "flag_update_selected_flags_#{flag.id}"
      click_button @update_button

      #Ensure The Flag Was Set to review state and the comment was moved to the item description
      expect(flag.reload.state).to eq Flag.review
      s=SolrDocument.find(druid)
      expect(s.description).to eq user_comment

      reindex_solr_docs(druid)

    end

    it "should allow users to add flags and then delete them without having their spam count increase" do
      druid='qb957rw1430'
      user_comment='I am a flag that has a tpyo in me!'
      starting_spam_count = get_user_spam_count(user_login)
      initial_flag_count=Flag.count

      #Login as a User and Leave A comment
      login_and_add_a_flag(user_login, druid, user_comment)

      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

      #Login As a Curator and delete the flag
      remove_flag(user_login, druid, user_comment)

      #Ensure The Flag Was Deleted On the Page and Database
      check_flag_was_deleted(user_login, druid, initial_flag_count)

      #Ensure the User Was NOT Penalized for Spam
      expect(get_user_spam_count(user_login)).to eq(starting_spam_count)
    end

    it "should allow a curator to resolve a flag as won't fix" do
        druid='qb957rw1430'
        user_comment="I am a comment that will be marked as won't fix."
        curator_comment='That was a bad flag and you should feel bad!'
        starting_spam_count = get_user_spam_count(user_login)
        initial_flag_count=Flag.count

        #Login as a User and Leave A comment
        login_and_add_a_flag(user_login, druid, user_comment)

        #Ensure the Flag Was Created On The Page and Database
        flag_id = check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

        # no notification
        expect(RevsMailer).not_to receive(:flag_resolved)

        #Login As a Curator and Mark It As Won't Fix
        resolve_flag_wont_fix(curator_login, druid, user_comment, curator_comment,flag_id)

        #Ensure the Flag Was Resolved via a message on the page to the user and in the database
        check_flag_was_marked_wont_fix(user_comment, initial_flag_count+1, curator_comment, flag_id)

        #Ensure the flag shows up in the flag history for the curator
        show_show_all_flagging_history(user_comment,curator_comment)

        #Ensure the flag doesn't show up in history for a non-logged in user or for a regular user who did not create it
        logout
        visit catalog_path(druid)
        show_not_show_flagging_history(user_comment,curator_comment)
        login_as_user_and_goto_druid(beta_login,druid)
        show_not_show_flagging_history(user_comment,curator_comment)

        #Ensure the flag show up in history for a the logged in user who created it
        login_as_user_and_goto_druid(user_login,druid)
        show_show_your_flagging_history(user_comment,curator_comment)

        #Ensure the flag show up in history for an admin  user
        login_as_user_and_goto_druid(admin_login,druid)
        show_show_all_flagging_history(user_comment,curator_comment)

    end

    it "should allow a curator to resolve a flag as fixed" do
        druid='qb957rw1430'
        user_comment="I am a comment that will be marked as fixed."
        curator_comment='This is a good flag and you should feel good!'
        starting_spam_count = get_user_spam_count(user_login)
        initial_flag_count=Flag.count

        #Login as a User and Leave A comment
        login_and_add_a_flag(user_login, druid, user_comment)

        #Ensure the Flag Was Created On The Page and Database
        flag_id = check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)

        # no notification
        expect(RevsMailer).not_to receive(:flag_resolved)

        #Login As a Curator and Mark It As Fixed
        resolve_flag_fix(curator_login, druid, user_comment, curator_comment,flag_id)

        #Ensure the Flag Was Resolved via a message on the page to the user and in the database
        check_flag_was_marked_fix(user_comment, initial_flag_count+1, curator_comment, flag_id)


    end

    it "should not allow flags by a user after the the user has posted the maxinum number of flags on an item; but not count anonymous flags" do

       druid = 'yh093pt9555'
       anon_comment='Anonymous comment.'
       first_user_comment="I am the first comment."
       other_comments="Bunch of bad flags."
       resolution="Closing bad flag"

       visit catalog_path(druid)
       create_flag(anon_comment)

       #The item should have no open flags on it by this user
       expect(Flag.where(:druid=>druid, :state=>Flag.open, :user_id=>User.where(:username=>user_login)[0].id).count).to eq(0)

       #Add an initial comment we can easily find and resolve
       login_and_add_a_flag(user_login, druid, first_user_comment)

       #Add comments up to the limit
       flags = 1
       while flags < Revs::Application.config.num_flags_per_item_per_user do
         create_flag("#{other_comments} #{flags}")
         flags += 1
       end

       #Ensure that you can no longer add a flag
       login_as_user_and_goto_druid(user_login, druid)
       should_not_allow_flagging

       #resolve the first flag
       resolve_flag_fix(curator_login, druid, first_user_comment, resolution, Flag.last.id)

       #Ensure the User Could Comment Again
       login_as_user_and_goto_druid(user_login, druid)
       should_allow_flagging

    end

    #This has been placed here, as opposed to user spec, since it needs to add and remove flags and makes use of variables declared in this spec
    it "should show all of a user's flags and show only the open ones by default" do
      druid='qb957rw1430'
      open_comment = "I am an unresolved comment"
      fixed_comment = "I am a comment that has been marked as fixed."
      wont_fix_comment = "I am a comment that has been marked as won't fix."
      comments = [open_comment, fixed_comment, wont_fix_comment]
      curator_fix_comment = "I have fixed this comment."
      curator_wont_fix_comment = "I won't fix this comment."
      select_id = "state_selection"

      login_as_user_and_goto_druid(user_login,druid)

      #Add the comments in by the user
      comments.each do |comment|
        create_flag(comment)
      end

      #Mark the fix comment as fixed
      resolve_flag_fix(curator_login, druid, fixed_comment, curator_fix_comment,Flag.where(:comment=>fixed_comment).first.id)

      #Mark the wont fix comment as fixed
      resolve_flag_wont_fix(curator_login, druid, wont_fix_comment, curator_wont_fix_comment,Flag.where(:comment=>wont_fix_comment).first.id)

      #Login as the user and go to their dashboard to see all flags
      logout
      login_as(user_login)
      user_account = User.find_by_username(user_login)
      table_header = "#{user_account.full_name}'s #{I18n.t('revs.flags.plural')}"
      visit user_flags_user_index_path(user_account.username)

      #Check the default of the user dashboard, by default we should see only the open comment
      has_content_array([table_header, open_comment])
      has_no_content_array([fixed_comment, wont_fix_comment, curator_fix_comment, curator_wont_fix_comment])

     #We can only test the default because PhantomJS is currently not implemented, so no AJAX reloads.


    end

end

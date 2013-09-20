require 'spec_helper'

describe("Flagging",:type=>:request,:integration=>true) do

  before :each do
    logout 
    @remove_button=I18n.t('revs.actions.remove')
    @flag_button=I18n.t('revs.flags.flag')
    @comment_field='flag_comment'
    @resolution_field = 'flag_resolution'
    @default_flag_type='error'
    @wont_fix_button=I18n.t('revs.flags.wont_fix')
    @fix_button=I18n.t('revs.flags.fixed')
  end
  
  it "should not show the flagging link if there are no flags to non-logged in users" do
    
    visit catalog_path('xf058ys1313')
    page.should have_css('#flag-details-link.hidden')
    
  end


  it "should allow non-logged in users to view flags for items that have them" do

    visit catalog_path('sc411ff4198')
    page.should_not have_css('#flag-details-link.hidden')
    page.should have_content("Flagged")
    page.should have_content("user comment") # the text of the flag
    find(".num-flags-badge").should have_content("1")
    
  end
  
  it "should allow logged in users to view flags" do

    login_as(user_login)
    visit catalog_path('sc411ff4198')
    find('.flag-details').should be_visible
    page.should have_content("Flag this item")
    page.should have_content("user comment") # the text of the flag
    find(".num-flags-badge").should have_content("1")

  end

  it "should not allow a user to flag an item more than the defined number of times" do
    
    login_as(user_login)
    visit catalog_path('sc411ff4198')
    find('.flag-details').should be_visible
    should_allow_flagging
    find(".num-flags-badge").should have_content("1")
    
    # add more flags up to 5
    for i in 2..Revs::Application.config.num_flags_per_item_per_user-1
      fill_in @comment_field, :with=>"comment #{i}"
      click_button @flag_button
      find(".num-flags-badge").should have_content("#{i}")
      should_allow_flagging
    end
  
    fill_in @comment_field, :with=>"last one!"
    click_button @flag_button
    should_not_allow_flagging # now we can't add any more!
      
  end
  
  it "should allow multiple logged in users to flag an item, show all flags, and then allow the user remove their own flag" do

      druid='qb957rw1430'
      initial_flag_count=Flag.count
            
      # login and visit an item as a regular user
      login_as(user_login)
      user_comment='all wrong!'
      item_page=catalog_path(druid)

      #flag the item
      visit item_page
      fill_in @comment_field, :with=>user_comment
      click_button @flag_button
      
      # check the page for the correct messages
      current_path.should == item_page
      page.should have_content(I18n.t('revs.flags.created'))
      page.should have_content(user_comment)
      page.should have_button(@remove_button)
      
      # check the database
      user=User.find_by_username(user_login)
      Flag.count.should == initial_flag_count + 1
      flag=Flag.last
      flag.comment.should == user_comment
      flag.flag_type.should == @default_flag_type
      flag.user=user

      # login and visit an item as a curator
      logout
      login_as(curator_login)
      curator_comment='not so bad'

      #flag the item
      visit item_page
      fill_in @comment_field, :with=>curator_comment
      click_button @flag_button
      
      # check the page for the correct messages
      current_path.should == item_page
      page.should have_content(I18n.t('revs.flags.created'))
      page.should have_content(curator_comment)
      page.should have_content(user_comment)
      page.should have_button(@remove_button)
      
      # check the database
      curator=User.find_by_username(curator_login)
      Flag.count.should == initial_flag_count + 2
      flag=Flag.last
      flag.comment.should == curator_comment
      flag.flag_type.should == @default_flag_type
      flag.user=curator
           
      # remove and confirm deletion of the curator's flag in the database
      #Since curators can remove any comment now, we need to target the removal of the comment that the curator just added
      remove_flag(curator_login, druid, curator_comment)
      
      page.should have_content(I18n.t('revs.flags.removed'))
      Flag.count.should == initial_flag_count + 1
      Flag.last.user.should == user     
    end
    
    it "should allow curators to delete flags set by any other user in the system and increase that user's spam count" do
    
      #Vars
      druid='qb957rw1430'
      user_comment='all wrong!'
      starting_spam_count = get_user_spam_count(user_login)
      initial_flag_count=Flag.count
      
      
      #Login as a User and Leave A comment
      add_a_flag(user_login, druid, user_comment)       
      
      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)
      
      #Login As a Curator and delete the flag
      remove_flag(curator_login, druid, user_comment)
      
      #Ensure The Flag Was Deleted On the Page and Database
      check_flag_was_deleted(user_login, initial_flag_count)

      #Ensure the User Was Penalized for Spam
      get_user_spam_count(user_login).should == starting_spam_count+1

    end
    
    it "should allow admins to delete flags set by any other user in the system and increase that user's spam count" do
    
      #Vars
      druid='qb957rw1430'
      user_comment='all wrong!'
      starting_spam_count = get_user_spam_count(user_login)
      initial_flag_count=Flag.count
     
      
      #Login as a User and Leave A comment
      add_a_flag(user_login, druid, user_comment)       
      
      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)
      
      #Login As a Curator and delete the flag
      remove_flag(admin_login, druid, user_comment)
      
      #Ensure The Flag Was Deleted On the Page and Database
      check_flag_was_deleted(user_login, initial_flag_count)

      #Ensure the User Was Penalized for Spam
      get_user_spam_count(user_login).should == starting_spam_count+1

    end
    
    it "should allow users to add flags and then delete them without having their spam count increase" do
      druid='qb957rw1430'
      user_comment='I am a flag that has a tpyo in me!'
      starting_spam_count = get_user_spam_count(user_login)
      initial_flag_count=Flag.count
      
      
      #Login as a User and Leave A comment
      add_a_flag(user_login, druid, user_comment)       
      
      #Ensure the Flag Was Created On The Page and Database
      check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)
      
      #Login As a Curator and delete the flag
      remove_flag(user_login, druid, user_comment)
      
      #Ensure The Flag Was Deleted On the Page and Database
      check_flag_was_deleted(user_login, initial_flag_count)

      #Ensure the User Was NOT Penalized for Spam
      get_user_spam_count(user_login).should == starting_spam_count 
    end
    
    it "should allow a curator to resolve a flag as won't fix" do
        druid='qb957rw1430'
        user_comment="I am a comment that will be marked as won't fix."
        curator_comment='That was a bad flag and you should feel bad!'
        starting_spam_count = get_user_spam_count(user_login)
        initial_flag_count=Flag.count
      
        #Login as a User and Leave A comment
        add_a_flag(user_login, druid, user_comment) 
      
        #Ensure the Flag Was Created On The Page and Database
        flag_id = check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)  
      
        #Login As a Curator and Mark It As Won't Fix
        resolve_flag_wont_fix(curator_login, druid, user_comment, curator_comment)
        
        #Ensure the Flag Was Resolved via a message on the page to the user and in the database
        check_flag_was_marked_wont_fix(user_comment, initial_flag_count+1, curator_comment, flag_id)
      
      
    end
    
    it "should allow a curator to resolve a flag as fixed" do
        druid='qb957rw1430'
        user_comment="I am a comment that will be marked as fixed."
        curator_comment='This is a good flag and you should feel good!'
        starting_spam_count = get_user_spam_count(user_login)
        initial_flag_count=Flag.count
      
        #Login as a User and Leave A comment
        add_a_flag(user_login, druid, user_comment) 
      
        #Ensure the Flag Was Created On The Page and Database
        flag_id = check_flag_was_created(user_login, druid, user_comment, initial_flag_count+1)  
      
        #Login As a Curator and Mark It As Fixed
        resolve_flag_fix(curator_login, druid, user_comment, curator_comment)
        
        #Ensure the Flag Was Resolved via a message on the page to the user and in the database
        check_flag_was_marked_fix(user_comment, initial_flag_count+1, curator_comment, flag_id)
      
      
    end
    
    
  
    
end

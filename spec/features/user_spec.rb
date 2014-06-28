require 'spec_helper'

describe("User registration system",:type=>:request,:integration=>true) do

  before :each do
    logout
  end
    
  it "should allow a user to login" do
    login_as(user_login)
    current_path.should == root_path
    page.should have_content('User Web') # username at top of page  
    page.should have_content('Signed in successfully.') # sign in message
    page.should_not have_content('Admin') # no admin menu on top of page
    page.should_not have_content('Curator') # no curator menu on top of page
  end

  it "should not allow a sunet user to login via the login form" do
    login_as(sunet_login)
    current_path.should == root_path
    page.should have_content('Stanford users must use webauth via SunetID to access their accounts.')
    page.should_not have_content(sunet_login) # username at top of page  
  end
  
  it "should allow a user to return to the page they were on and not see the admin or curator interface (since they are not admins or curators)" do
    starting_page=catalog_path('qb957rw1430')
    visit starting_page
    should_allow_flagging # anonymous users can flag items
    should_not_allow_annotations
    login_as(user_login)
    current_path.should == starting_page
    should_allow_flagging
    should_allow_annotations    
    should_deny_access(admin_users_path)
    should_deny_access(curator_tasks_path)
  end
  
  it "should not show the public profile of a user who does not want their profile public, but should show the public profile page for users who do have it set as public" do
    admin_account=get_user(admin_login)
    user_account=get_user(user_login)
    admin_account.public.should == false
    user_account.public.should == true
    user_account.active.should == true

    # admin user profile is not public
    visit user_path(admin_account)
    current_path.should == root_path
    page.should have_content 'You are not authorized to access this page.'

    # regular user profile is public and should be available via ID or full name
    visit user_path(user_account.id)
    current_path.should == user_path(user_account.id)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}
    visit user_path(user_account.username)
    current_path.should == user_path(user_account.username)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}    
  end

  it "should not show the public profile of a user whose account is marked as inactive, unless they are an admin" do
    user_account=get_user(user_login)
    user_account.public.should == true
    user_account.active = false
    user_account.save

    # regular user profile is public but inactive and should not be shown
    visit user_path(user_account)
    current_path.should_not == user_path(user_account)    
    visit user_path(user_login)
    current_path.should_not == user_path(user_login)    
    
    login_as(admin_login) # now confirm the admin can still see it
    visit user_path(user_login)
    current_path.should == user_path(user_login)    
  end

  it "should not show the public profile of a user whose account is marked as inactive, unless they are an admin" do
    user_account=get_user(user_login)
    user_account.public.should == true
    user_account.active = false
    user_account.save

    # regular user profile is public but inactive and should not be shown
    visit user_path(user_account)
    current_path.should_not == user_path(user_account)    
    visit user_path(user_login)
    current_path.should_not == user_path(user_login)    
    
    login_as(admin_login) # now confirm the admin can still see it
    visit user_path(user_login)
    current_path.should == user_path(user_login)    
  end

  it "should deny access when a user attempts to access a non-existent user profile (not giving them a clue that it doesn't exist)" do
    visit user_path("bogus")
    current_path.should == root_path
    page.should have_content I18n.t('revs.authentication.user_not_found')
  end

  it "should allow access to a public user account by user id as well as username" do
    user_account=get_user(user_login)
    user_account.public.should be_true
    visit user_path(user_account.id)
    current_path.should == user_path(user_account.id)
    visit user_path(user_account.username)
    current_path.should == user_path(user_account.username)
  end
      
  it "should show a user's profile page when logged in as themselves, even if their profile is marked as private, and should always let admins view it" do
    # make user account private
    user_account=get_user(user_login)
    user_account.public = false
    user_account.save

    login_as(user_login)

    visit user_path(user_login)
    current_path.should == user_path(user_login)
    [user_account.full_name,user_account.bio].each {|content| page.should have_content content}
    page.should have_content 'private'
    
    logout
    login_as(admin_login)

    visit user_path(user_login)
    current_path.should == user_path(user_login)
    [user_account.username,user_account.bio].each {|content| page.should have_content content}
    
  end

  it "should show a user's profile even if they don't have a favorites list yet, which will be created upon viewing" do
    beta_user=get_user(beta_login)
    beta_user.favorites_list.should be_nil # doesn't exist yet
    visit user_path(beta_login)
    beta_user.reload
    beta_user.favorites_list.should_not be_nil # favorites list now exists for this user, so we can render the page
    current_path.should == user_path(beta_login)
    [beta_user.to_s,beta_user.bio].each {|content| page.should have_content content}
  end


  it "should show link to annotations made by user on that user's profile page, only if user has made annotations" do
    login_as(user_login) # this user has annotations
    visit user_path(user_login)
    current_path.should == user_path(user_login)
    page.should have_content I18n.t('revs.user.view_your_annotations')
    logout

    login_as(beta_login) # this user does not have annotations
    visit user_path(beta_login)
    current_path.should == user_path(beta_login)
    page.should_not have_content I18n.t('revs.user.view_your_annotations')
  end

  it "should show correct number of annotations made by user on that user's profile page, along with most recent annotations and flags" do
    login_as(admin_login)
    visit user_path(admin_login)
    current_path.should == user_path(admin_login)
    page.should have_content 'Annotations 2'
    logout

    login_as(user_login)
    visit  user_path(user_login)
    current_path.should ==  user_path(user_login)
    ["Annotations 1","air intake?","Flags","Sebring 12 Hour, Green Park Straight, January 4"].each {|title| page.should have_content(title)}
  end

  it "should show hidden item annotations to the curator, but not to non-logged in user" do
    login_as(curator_login)
    visit user_path(curator_login)
    current_path.should == user_path(curator_login)
    page.should have_content 'Annotations 1' # the curators annotation is hidden, but visible to them since they are logged in
    page.should have_content I18n.t('revs.user.view_your_annotations')
    logout

    visit user_path(curator_login)
    current_path.should ==  user_path(curator_login)
    page.should have_content I18n.t('revs.annotations.none') # none are visible since the only one is hidden
  end

  it "should show correct number of item edits made by user on that user's profile page, along with most recent item edits" do
    edited_titles=["A Somewhat Shorter Than Average Title","Marlboro Governor's Cup, April 2-3","Thompson Raceway, May 1"]
    login_as(curator_login)
    visit user_path(curator_login)
    current_path.should == user_path(curator_login)
    page.should have_content 'Item Edits 3'
    edited_titles.each {|title| page.should have_content(title)}    
    visit user_edits_user_index_path(curator_login)
    edited_titles.each {|title| page.should have_content(title)}        
  end

  it "should show a profile preview link on edit profile page, but only if user profile is private" do
    login_as(admin_login) # profile page is private
    visit edit_user_registration_path
    current_path.should == edit_user_registration_path
    page.should have_link('Preview', href: user_path(admin_login))
    logout

    login_as(user_login) # profile page is public
    visit edit_user_registration_path
    current_path.should == edit_user_registration_path
    page.should_not have_link('Preview', href: user_path(user_login))
  end

  it "show the logged in users annotations/flags/edits with their full name, even if the profile is private" do
    login_as(admin_login)
    admin_account=get_user(admin_login)
    admin_account.public.should == false
    visit user_annotations_user_index_path(admin_account.username)
    page.should have_content "#{admin_account.full_name}'s Annotations"
    page.should have_content "Guy in the background looking sideways"
    visit user_flags_user_index_path(admin_account.username)    
    page.should have_content "#{admin_account.full_name}'s Flags"
    page.should have_content "You do not have any flags."   
    visit user_edits_user_index_path(admin_account.username)    
    page.should have_content "#{admin_account.full_name}'s Item Edits"
    page.should have_content "A Somewhat Shorter Than Ave"     
  end

  it "show a non logged in users annotations/flags/edits with just their username, even if the profile is private, and should only show favorites if those are set as public" do
    admin_account=get_user(admin_login)
    admin_account.public.should == false
    visit user_favorites_user_index_path(admin_account.username)  
    page.should have_content I18n.t('revs.user.view_all_favorites') # favorites link shows up since they are public
    page.should_not have_content admin_account.full_name
    page.should_not have_content I18n.t('revs.favorites.none') # favorites show up

    visit user_annotations_user_index_path(admin_account.username)
    page.should have_content "#{admin_account.username}'s Annotations"
    page.should have_content "Guy in the background looking sideways"
    visit user_flags_user_index_path(admin_account.username)    
    page.should have_content "#{admin_account.username}'s Flags"
    page.should have_content "This user does not have any flags."  
    visit user_edits_user_index_path(admin_account.username)    
    page.should have_content "#{admin_account.username}'s Item Edits"
    page.should have_content "A Somewhat Shorter Than Ave"

    # we should be able to see the favorites if they are public
    admin_account.favorites_public.should be_true
    visit user_favorites_user_index_path(admin_account.username)  
    current_path.should ==  user_favorites_user_index_path(admin_account.username) 
    page.should_not have_content "You are not authorized to access this page."
    page.should have_content "Marlboro 12 Hour, August 12-14"

    # make favorites private    
    admin_account.favorites_public=false
    admin_account.save
    admin_account.favorites_public.should be_false

    # we should NOT be able to see the favorites if they are private
    visit user_annotations_user_index_path(admin_account.username)
    page.should_not have_content I18n.t('revs.user.view_all_favorites') # no favorites link since profile is private
    visit user_favorites_user_index_path(admin_account.username)  # we should not be able to see the favorites if they are private
    current_path.should_not ==  user_favorites_user_index_path(admin_account.username) 
    page.should have_content "You are not authorized to access this page."

    # make admin account public and check that favorites still do not show up (since we just made them private above)
    admin_account.public=true
    admin_account.save
    visit user_path(admin_account.username)
    page.should_not have_link(I18n.t('revs.user.view_all_favorites'), href: user_favorites_user_index_path(admin_account.username)) # favorites link should not show up since they are still private
    page.should have_content I18n.t('revs.favorites.none')
    visit user_favorites_user_index_path(admin_account.username)  # we still should not be able to see the favorites
    current_path.should_not ==  user_favorites_user_index_path(admin_account.username) 
  end

  it "show a non logged in users annotations/flags with their full name if their profile is public" do
    user_account=get_user(user_login)
    user_account.public.should == true
    visit user_annotations_user_index_path(user_account.username)    
    page.should have_content "#{user_account.full_name}'s Annotations"
    page.should have_content "air intake?"
    visit user_flags_user_index_path(user_account.username)    
    page.should have_content "#{user_account.full_name}'s Flags"
    page.should have_content "user comment"    
    visit user_edits_user_index_path(user_account.username)    
    page.should have_content "#{user_account.full_name}'s Item Edits"
    page.should have_content "This user does not have any edits."    
  end
  
  it "should show only the dashboard links appropriate for role of user" do
    login_as(admin_login)
    visit user_path(admin_login)
    current_path.should == user_path(admin_login)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content  I18n.t('revs.user.curator_dashboard')
    page.should have_content  I18n.t('revs.user.admin_dashboard')
    logout

    login_as(curator_login)
    visit user_path(curator_login)
    current_path.should ==  user_path(curator_login)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should have_content  I18n.t('revs.user.curator_dashboard')
    page.should_not have_content  I18n.t('revs.user.admin_dashboard')
    logout

    login_as(user_login)
    visit user_path(user_login)
    current_path.should ==  user_path(user_login)
    page.should have_content(I18n.t("revs.user.user_dashboard",:name=>I18n.t('revs.user.your')))
    page.should_not have_content  I18n.t('revs.user.curator_dashboard')
    page.should_not have_content  I18n.t('revs.user.admin_dashboard')
  end

  it "should show a user's website link, if it has been provided by the user" do
    login_as(user_login)
    visit user_path(user_login)
    current_path.should ==  user_path(user_login)
    find_link('www.example.com/user1/my-website').visible?
  end

  it "should show a user's Twitter link, if it has been provided by the user" do
    login_as(user_login)
    visit user_path(user_login)
    current_path.should ==  user_path(user_login)
    find_link('@RevsTesting').visible?
  end

  it "should destroy all dependent annotations, galleries, flags and saved items when a user is removed" do
    
    user=get_user(user_login)
    user_flags=user.all_flags.count
    total_flags=Flag.count
    user_flags.should == 1 
    total_flags.should == 3

    user_annotations=user.all_annotations.count
    total_annotations=Annotation.count
    user_annotations.should == 1
    total_annotations.should == 4

    user_galleries=user.all_galleries.count
    user_galleries_public=user.galleries.count
    user_galleries_including_private=user.galleries(user).count
    total_galleries=Gallery.count
    user_galleries.should == 5
    user_galleries_public.should == 3
    user_galleries_including_private.should == 4
    total_galleries.should == 9

    user_saved_items=user.all_saved_items.count
    total_saved_items=SavedItem.count
    user_saved_items.should == 4
    total_saved_items.should == 12

    # now kill the user
    user.destroy

    # now check the counts have gone down by the right amounts
    Flag.count.should == total_flags - user_flags
    Annotation.count.should == total_annotations - user_annotations
    Gallery.count.should == total_galleries - user_galleries
    SavedItem.count.should == total_saved_items - user_saved_items

  end

  it "should destroy all dependent change logs when a curator is removed" do
    
    curator=get_user(curator_login)
    curator_change_logs=curator.all_change_logs.count
    curator_metadata_updates=curator.metadata_updates.count.keys.count
    total_change_logs=ChangeLog.count
    curator_change_logs.should == 4 
    curator_metadata_updates.should == 3 
    total_change_logs.should == 5

    # now kill the user
    curator.destroy

    # now check the counts have gone down by the right amounts
    ChangeLog.count.should == total_change_logs - curator_change_logs

  end 

end

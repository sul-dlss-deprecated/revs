require "rails_helper"

describe("Galleries",:type=>:request,:integration=>true) do

  before :each do
    logout 
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
    @add_to_gallery='Add'
    @gallery_drop_down='saved_item_gallery_id'
    @gallery1_title='My Awesome Gallery'
    @gallery2_title='Porsche Gallery'
    @featured_gallery='A Featured Gallery'
    @curator_only_gallery_title='Stuff to work on'
    @num_user_galleries=4 # from fixtures
  end
  
  it "should show featured gallery on gallery landing page in both grid and detailed view" do
    [galleries_path,galleries_path(:view=>'detailed')].each do |url|
        visit url
        expect(page).to have_content @featured_gallery
        expect(page).to have_content "(2 items)"
    end
  end
  
  it "should not show any curated gallery tab if there are none" do
    visit galleries_path
    expect(page).not_to have_content I18n.t('revs.nav.curator')
  end

  it "should show any curated galleries in both grid and detailed view" do

    curator_gallery_title='Stuff to work on'

    # initially we don't see the curator gallery, since it is set to curator only mode
    [galleries_path(:filter=>'curator'),galleries_path(:filter=>'curator',:view=>'detailed')].each do |url|
        visit url
        expect(page).not_to have_content curator_gallery_title 
    end

    # make the curator only gallery public
    gallery=Gallery.where(:title=>curator_gallery_title).first
    gallery.visibility = :public
    gallery.save

    # now it should show up
    [galleries_path(:filter=>'curator'),galleries_path(:filter=>'curator',:view=>'detailed')].each do |url|
        visit url
        expect(page).to have_content curator_gallery_title 
    end
  end

  it "should show the correct galleries on the user tab in both grid and detailed view (ignoring a public gallery with no items)" do
    [galleries_path(:filter=>'user'),galleries_path(:filter=>'user',:view=>'detailed')].each do |url|
        visit url 
        expect(page).not_to have_content 'An empty public gallery'
        expect(page).to have_content @gallery1_title
        expect(page).to have_content @featured_gallery
    end
  end


  it "should not show the add to gallery button for non-logged in users" do
    visit catalog_path(@druid1)
    should_not_have_button(@add_to_gallery)
  end

  it "should show the add to gallery button for a logged in users and allow a user to add an item to a gallery" do
    user=get_user(user_login)
    gallery=user.galleries.where(:title=>@gallery1_title).first
    login_as(user_login)
    gallery.saved_items(user).count == 0 # no items in this gallery yet
    
    visit catalog_path(@druid1)
    should_have_button(@add_to_gallery)
    select @gallery1_title,:from=>@gallery_drop_down
    click_button @add_to_gallery
    
    gallery.reload
    gallery.saved_items(user).count == 1 # now we have an item in this gallery
  end
  
  it "should show user galleries on their profile page and should show the page with all user galleries" do
    user=get_user(user_login)
    login_as(user_login)
    visit user_path(user)
    expect(page).to have_content @gallery1_title 
    expect(page).to have_content @featured_gallery
    click_link I18n.t('revs.user.view_your_galleries')
    expect(page).to have_content "#{user.to_s}'s #{I18n.t('revs.user_galleries.head')}"
    expect(page).to have_content @gallery1_title 
    expect(page).to have_content @featured_gallery
    expect(page).to have_content @gallery2_title 
    expect(page).to have_content "An empty public gallery"
  end

  it "should show only the user's public galleries on their public profile page" do
    user=get_user(user_login)
    visit user_path(user)
    expect(page).to have_content @gallery1_title # public gallery
    expect(page).not_to have_content @gallery2_title # private gallery
    click_link I18n.t('revs.user.view_all_galleries')
    expect(page).to have_content "#{user.to_s}'s #{I18n.t('revs.user_galleries.head')}"
    expect(page).to have_content @gallery1_title  # public
    expect(page).not_to have_content @gallery2_title # private
    should_deny_access_to_named_gallery(@gallery2_title) # can't get to the private gallery directly
  end

  it "should not show a curator only gallery to a non-curator and a non-logged in user" do
    curator=get_user(curator_login)
    visit user_path(curator)
    expect(page).not_to have_content @curator_only_gallery_title # curator gallery
    expect(page).not_to have_content  I18n.t('revs.user.view_your_galleries')
    should_deny_access_to_named_gallery(@curator_only_gallery_title) # can't get to the curator only gallery directly when not logged in

    login_as(user_login)
    visit user_path(curator)
    expect(page).not_to have_content @curator_only_gallery_title # curator gallery
    expect(page).not_to have_link(I18n.t('revs.user.view_all_galleries'), href: user_galleries_user_index_path(curator_login))
    should_deny_access_to_named_gallery(@curator_only_gallery_title) # can't get to the curator only gallery directly when logged in as a non-curator
  end

   it "should allow the curator or administrator access to the curator only gallery" do
    curator=get_user(curator_login)   
    login_as(curator_login)
    visit user_path(curator)
    expect(page).to have_content @curator_only_gallery_title # curator gallery
    expect(page).to have_content  I18n.t('revs.user.view_your_galleries')
    should_allow_access_to_named_gallery(@curator_only_gallery_title) # can get to the curator only gallery directly when logged in as yourself

    login_as(admin_login)
    visit user_path(curator)
    expect(page).to have_content @curator_only_gallery_title # curator gallery
    expect(page).to have_content  I18n.t('revs.user.view_all_galleries')
    should_allow_access_to_named_gallery(@curator_only_gallery_title) # can get to the curator only gallery directly when logged in as an admin
  end

  it "should not show any galleries when a user doesn't have any" do
    user=get_user(admin_login)
    visit user_galleries_user_index_path(admin_login)
    expect(page).to have_content "#{user.to_s}'s #{I18n.t('revs.user_galleries.head')}"
    expect(page).to have_content I18n.t('revs.user_galleries.none')
  end

  it "should allow a user to view a public gallery but not a private gallery" do
    user=get_user(user_login)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    gallery2=Gallery.where(:title=>@gallery2_title).first
    visit gallery_path(gallery1)
    expect(page).to have_content "#{I18n.t('revs.messages.created_by')} #{user.full_name}"
    expect(page).to have_content @gallery1_title
    should_deny_access(gallery_path(gallery2)) # private, get booted out to home page
  end

  it "should not allow a non-logged in user to create a gallery" do
    should_deny_access(new_gallery_path) 
  end

  it "should allow a logged in user to create a gallery with private as the default" do
    new_gallery_title='This is my new gallery'
    new_gallery_description='It rulz'
    user=get_user(user_login)
    login_as(user_login)
    expect(user.galleries(user).count).to eq(@num_user_galleries) # these are from the fixtures
    visit new_gallery_path
    fill_in 'gallery_title', :with=>new_gallery_title
    fill_in 'gallery_description', :with=>new_gallery_description
    click_button 'submit'
    expect(current_path).to eq(user_galleries_user_index_path(user_login))
    expect(page).to have_content(new_gallery_title)
    expect(page).to have_content(new_gallery_description)
    expect(user.galleries(user).count).to eq(@num_user_galleries + 1) # now we have a new gallery
    new_gallery=Gallery.where(:user_id=>user.id).last
    expect(new_gallery.public).to be_falsey 
    expect(new_gallery.visibility).to eq('private')
    expect(new_gallery.title).to eq(new_gallery_title)
    expect(new_gallery.description).to eq(new_gallery_description)
  end

  it "should allow a logged in user to create a gallery set as public" do
    new_gallery_title='This is my new gallery'
    new_gallery_description='It rulz'
    user=get_user(user_login)
    login_as(user_login)
    expect(user.galleries(user).count).to eq(@num_user_galleries) # these are from the fixtures
    visit new_gallery_path
    fill_in 'gallery_title', :with=>new_gallery_title
    fill_in 'gallery_description', :with=>new_gallery_description
    choose 'gallery_visibility_public'
    click_button 'submit'
    expect(current_path).to eq(user_galleries_user_index_path(user_login))
    expect(page).to have_content(new_gallery_title)
    expect(page).to have_content(new_gallery_description)
    expect(user.galleries(user).count).to eq(@num_user_galleries + 1) # now we have a new gallery
    new_gallery=Gallery.where(:user_id=>user.id).last
    expect(new_gallery.public).to be_truthy
    expect(new_gallery.visibility).to eq('public')
    expect(new_gallery.title).to eq(new_gallery_title)
    expect(new_gallery.description).to eq(new_gallery_description)
  end

  it "should allow a logged in user to delete their own gallery" do
    user=get_user(user_login)
    login_as(user_login)
    expect(user.galleries(user).count).to eq(@num_user_galleries) # these are from the fixtures
    visit user_galleries_user_index_path(user_login)
    expect(page).to have_content(@gallery1_title)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    click_button "delete_#{gallery1.id}"
    expect(page).not_to have_content(@gallery1_title)
    expect(user.galleries(user).count).to eq(@num_user_galleries - 1) # you just deleted it
  end 

  it "should allow a logged in user to edit their own gallery" do
    new_gallery_title="It was even better now"
    user=get_user(user_login)
    login_as(user_login)
    visit user_galleries_user_index_path(user_login)
    expect(page).to have_content(@gallery1_title)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    click_link "edit_#{gallery1.id}"
    fill_in 'gallery_title', :with=>new_gallery_title
    click_button 'submit'    
    expect(page).not_to have_content(@gallery1_title)
    expect(page).to have_content(new_gallery_title)
  end 

  it "should not allow a logged in user or anonynous user to edit someone else's gallery" do
    gallery1=Gallery.where(:title=>@gallery1_title).first
    should_deny_access(edit_gallery_path(gallery1))  # try and edit a user1 gallery
    login_as(admin_login)
    should_deny_access(edit_gallery_path(gallery1))  # try and edit a user1 gallery logged in as admin
  end

  it "should not allow a logged in user or anonynous user to delete someone else's gallery" do
    gallery1=Gallery.where(:title=>@gallery1_title).first
    expect {delete gallery_path(gallery1)}.not_to change(Gallery, :count)
    login_as(admin_login)
    expect {delete gallery_path(gallery1)}.not_to change(Gallery, :count)
  end 

  it "should allow a user to return to the gallery view page after clicking on a gallery item" do
    item_name="A Somewhat Shorter Than Average Title"
    hidden_item_name="Bryar 250 Trans-American:10"
    return_link_name=I18n.t('revs.nav.return_to_gallery').gsub('&laquo; ','')
    gallery1=Gallery.where(:title=>@gallery1_title).first
    visit gallery_path(gallery1)
    click_link item_name
    expect(page).to have_content(item_name)
    expect(page).to have_content(@gallery1_title)
    expect(page).not_to have_content(hidden_item_name)
    expect(page).to have_content return_link_name
    click_link return_link_name
    expect(current_path).to eq(gallery_path(gallery1))
  end
   
end
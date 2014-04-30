require 'spec_helper'

describe("Galleries",:type=>:request,:integration=>true) do

  before :each do
    logout 
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
    @add_to_gallery='Add'
    @gallery_drop_down='saved_item_gallery_id'
    @gallery1_title='My Awesome Gallery'
    @gallery2_title='Porsche Gallery'
  end
  
  it "should not show the add to gallery button for non-logged in users" do
    visit catalog_path(@druid1)
    should_not_have_button(@add_to_gallery)
  end

  it "should show the add to gallery button for a logged in users and allow a user to add an item to a gallery" do
    user=get_user(user_login)
    gallery=user.galleries.where(:title=>@gallery1_title).first
    login_as(user_login)
    gallery.saved_items.count == 0 # no items in this gallery yet
    
    visit catalog_path(@druid1)
    should_have_button(@add_to_gallery)
    select @gallery1_title,:from=>@gallery_drop_down
    click_button @add_to_gallery
    
    gallery.reload
    gallery.saved_items.count == 1 # now we have an item in this gallery
  end
  
  it "should show user galleries on their profile page and should show the page with all user galleries" do
    user=get_user(user_login)
    login_as(user_login)
    visit user_profile_id_path(user.id)
    page.should have_content @gallery1_title 
    page.should have_content @gallery2_title
    click_link I18n.t('revs.user.view_your_galleries')
    page.should have_content "#{user.full_name}'s #{I18n.t('revs.user_galleries.head')}"
    page.should have_content @gallery1_title 
    page.should have_content @gallery2_title
  end

  it "should show only the user's public galleries on their public profile page" do
    user=get_user(user_login)
    visit user_galleries_path(user_login)
    page.should have_content @gallery1_title # public gallery
    page.should_not have_content @gallery2_title # private gallery
    click_link I18n.t('revs.user.view_all_galleries')
    page.should have_content "#{user.full_name}'s #{I18n.t('revs.user_galleries.head')}"
    page.should have_content @gallery1_title  # public
    page.should_not have_content @gallery2_title # private
  end

  it "should not show any galleries when a user doesn't have any" do
    user=get_user(admin_login)
    visit user_galleries_path(admin_login)
    page.should have_content "#{user.to_s}'s #{I18n.t('revs.user_galleries.head')}"
    page.should have_content I18n.t('revs.user_galleries.none')
  end

  it "should not allow a user to view a public gallery but not a private gallery" do
    user=get_user(user_login)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    gallery2=Gallery.where(:title=>@gallery2_title).first
    visit gallery_path(gallery1)
    page.should have_content "#{I18n.t('revs.messages.created_by')} #{user.full_name}"
    page.should have_content @gallery1_title
    should_deny_access(gallery_path(gallery2)) # private, get booted out to home page
  end

  it "should not allow a non-logged in user to create a gallery" do
    should_deny_access(new_gallery_path) 
  end

  it "should allow a logged in user to create a gallery" do
    new_gallery_title='This is my new gallery'
    new_gallery_description='It rulz'
    user=get_user(user_login)
    login_as(user_login)
    user.galleries.count.should == 2 # these are from the fixtures
    visit new_gallery_path
    fill_in 'gallery_title', :with=>new_gallery_title
    fill_in 'gallery_description', :with=>new_gallery_description
    click_button 'submit'
    current_path.should == user_galleries_path(user_login)
    page.should have_content(new_gallery_title)
    page.should have_content(new_gallery_description)
    user.galleries.count.should == 3 # now we have a new gallery
    new_gallery=user.galleries.last
    new_gallery.public = false # default to private
    new_gallery.title=new_gallery_title
    new_gallery.description=new_gallery_description
  end

  it "should allow a logged in user to delete their own gallery" do
    user=get_user(user_login)
    login_as(user_login)
    user.galleries.count.should == 2 # these are from the fixtures
    visit user_galleries_path(user_login)
    page.should have_content(@gallery1_title)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    click_button "delete_#{gallery1.id}"
    page.should_not have_content(@gallery1_title)
    user.galleries.count.should == 1 # you just deleted it
  end 

  it "should allow a logged in user to edit their own gallery" do
    new_gallery_title="It was even better now"
    user=get_user(user_login)
    login_as(user_login)
    visit user_galleries_path(user_login)
    page.should have_content(@gallery1_title)
    gallery1=Gallery.where(:title=>@gallery1_title).first
    click_link "edit_#{gallery1.id}"
    fill_in 'gallery_title', :with=>new_gallery_title
    click_button 'submit'    
    page.should_not have_content(@gallery1_title)
    page.should have_content(new_gallery_title)
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
   
end
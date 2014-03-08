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
  
end
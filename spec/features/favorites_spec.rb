require 'spec_helper'

describe("Favorites",:type=>:request,:integration=>true) do

  before :each do
    logout 
    @save_favorites_button=I18n.t('revs.favorites.save_to_favorites')
    @remove_favorites_button=I18n.t('revs.favorites.remove_from_favorites')
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
  end
  
  it "should not show save/remove favorites link for non-logged in users" do
    visit catalog_path(@druid1)
    should_not_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)    
  end

  it "should show save favorites link for a logged in user and allow them to add a favorite" do
   
    user=get_user(user_login)
    login_as(user_login)
    visit catalog_path(@druid1)
    should_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)    
    
    # check database to be sure there are actually no favorites for this item
    SavedItem.where(:druid=>@druid1).size.should == 0

    click_button(@save_favorites_button) # save the favorite

    should_not_have_button(@save_favorites_button) # button switches to remove
    should_have_button(@remove_favorites_button)    

    saved_items=SavedItem.where(:druid=>@druid1)
    saved_items.size.should == 1 # favorite is now saved
    saved_items.first.gallery.user_id=user.id # and it belongs to this user
    Gallery.where(:user_id=>user.id).first.saved_items.size.should == 1 # now we have one!
        
    # druid2 is not a favorite yet
    visit catalog_path(@druid2)
    should_have_button(@save_favorites_button)
    should_not_have_button(@remove_favorites_button)
    click_button(@save_favorites_button) # save it!
    saved_items=SavedItem.where(:druid=>@druid2)
    saved_items.size.should == 1 # favorite is now saved
    saved_items.first.gallery.user_id=user.id # and it belongs to this user
    Gallery.where(:user_id=>user.id).first.saved_items.size.should == 2 # now we have two favorites for this user!

    click_button(@remove_favorites_button) # get rid of the favorite

    should_have_button(@save_favorites_button) # button switches back to add
    should_not_have_button(@remove_favorites_button)    
    
    # favorite is gone
    SavedItem.where(:druid=>@druid2).size.should == 0
    Gallery.where(:user_id=>user.id).first.saved_items.size.should == 1 # now we have one favorite for this user!
    
  end
  
end
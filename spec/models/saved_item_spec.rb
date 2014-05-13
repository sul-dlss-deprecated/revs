require "spec_helper"

describe SavedItem do
  
  before :each do
    @user=get_user(user_login)
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
  end
  
  it "should save a favorite in a user's favorite gallery" do
    @user.favorites_list.class.should == Gallery # we can find the new gallery
    @user.favorites.size.should == 0
    SolrDocument.find(@druid1).is_favorite?(@user).should be_false
    SolrDocument.find(@druid2).is_favorite?(@user).should be_false
    SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid1,:description=>'test').id.should_not be_nil # save a favorite
    @user.favorites.reload.size.should == 1 # there is one saved favorite for this user
    SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid2,:description=>'test2').id.should_not be_nil # save another one
    Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size.should == 1 # still only one favorites gallery
    @user.favorites.reload.size.should == 2
    SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid2,:description=>'test2').id.should be_nil # save the same druid, which should not add it again
    Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size.should == 1 # still only one favorites gallery
    @user.favorites.reload.size.should == 2 # still only two saved items in this gallery    
    SolrDocument.find(@druid1).is_favorite?(@user).should be_true
    SolrDocument.find(@druid2).is_favorite?(@user).should be_true
  end
  
  it "should remove a favorite from the favorites gallery" do
    @user.favorites_list.class.should == Gallery # we can find the new gallery
    @user.favorites.size.should == 0
    SolrDocument.find(@druid1).is_favorite?(@user).should be_false
    SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid1,:description=>'test').id.should_not be_nil # save a favorite
    @user.favorites.reload.size.should == 1 # there is one saved favorite for this user
    SolrDocument.find(@druid1).is_favorite?(@user).should be_true
    SavedItem.remove_favorite(:user_id=>@user.id,:druid=>@druid1)
    @user.favorites.reload.size.should == 0 # there are no saved favorites for this user
    Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size.should == 1 # but gallery still exists
    SolrDocument.find(@druid1).is_favorite?(@user).should be_false
  end
  
end

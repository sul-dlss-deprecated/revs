require "spec_helper"

describe SavedItem do
  
  before :each do
    @user=get_user(user_login)
    @druid1='qk978vx9753'
    @druid2='dd482qk0417'
  end
  
  it "should save a favorite in a user's favorite gallery" do
    expect(@user.favorites_list.class).to eq(Gallery) # we can find the new gallery
    expect(@user.favorites.size).to eq(0)
    expect(SolrDocument.find(@druid1).is_favorite?(@user)).to be_false
    expect(SolrDocument.find(@druid2).is_favorite?(@user)).to be_false
    expect(SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid1,:description=>'test').id).not_to be_nil # save a favorite
    expect(@user.favorites.reload.size).to eq(1) # there is one saved favorite for this user
    expect(SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid2,:description=>'test2').id).not_to be_nil # save another one
    expect(Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size).to eq(1) # still only one favorites gallery
    expect(@user.favorites.reload.size).to eq(2)
    expect(SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid2,:description=>'test2').id).to be_nil # save the same druid, which should not add it again
    expect(Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size).to eq(1) # still only one favorites gallery
    expect(@user.favorites.reload.size).to eq(2) # still only two saved items in this gallery    
    expect(SolrDocument.find(@druid1).is_favorite?(@user)).to be_true
    expect(SolrDocument.find(@druid2).is_favorite?(@user)).to be_true
  end
  
  it "should remove a favorite from the favorites gallery" do
    expect(@user.favorites_list.class).to eq(Gallery) # we can find the new gallery
    expect(@user.favorites.size).to eq(0)
    expect(SolrDocument.find(@druid1).is_favorite?(@user)).to be_false
    expect(SavedItem.save_favorite(:user_id=>@user.id,:druid=>@druid1,:description=>'test').id).not_to be_nil # save a favorite
    expect(@user.favorites.reload.size).to eq(1) # there is one saved favorite for this user
    expect(SolrDocument.find(@druid1).is_favorite?(@user)).to be_true
    SavedItem.remove_favorite(:user_id=>@user.id,:druid=>@druid1)
    expect(@user.favorites.reload.size).to eq(0) # there are no saved favorites for this user
    expect(Gallery.where(:user_id=>@user.id,:gallery_type=>'favorites').size).to eq(1) # but gallery still exists
    expect(SolrDocument.find(@druid1).is_favorite?(@user)).to be_false
  end
  
end

require 'spec_helper'

describe("Annotation of images",:type=>:request,:integration=>true) do

  before :each do
    logout
    @starting_page=catalog_path('qb957rw1430')
  end

  it "should show the number of annotations in an image and allow logged in users to add a new one" do
    login_as(user_login)
    visit @starting_page
    should_allow_annotations    
    page.should have_content('(2 existing)')
  end

  it "should add/update the annotations to the right field in solr when adding/updating annotations" do
    druid='dd482qk0417'
    
    # find the solr doc and confirm there is no annotation listed
    item=Item.find(druid)
    item['annotations_tsim'].should be_nil
  
    # create an annotation
    comment1='some comment'
    user_account=User.find_by_email(user_login)
    annotation1=Annotation.create(:druid=>druid,:text=>comment1,:json=>'{a bunch of json would go here}',:user_id=>user_account.id)

    # confirm that solr has been updated
    item=Item.find(druid)
    item['annotations_tsim'].should == [comment1]
    
    comment2='second comment'
    # create the second annotation
    annotation2=Annotation.create(:druid=>druid,:text=>comment2,:json=>'{a bunch of json would go here}',:user_id=>user_account.id)

    # confirm that solr has been updated
    item=Item.find(druid)
    item['annotations_tsim'].should == [comment1,comment2]
    
    updated_comment1='changed my mind'
    # update the first annotation
    annotation1.text=updated_comment1
    annotation1.save

    # confirm that solr has been updated
    item=Item.find(druid)
    item['annotations_tsim'].should == [updated_comment1,comment2]
    
  end
    
end
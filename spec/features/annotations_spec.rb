require 'spec_helper'

describe("Annotation of images",:type=>:request,:integration=>true) do

  before :each do
    logout
    @starting_page=catalog_path('qb957rw1430')
  end

  it "should not show the annotations for a disabled user" do
    visit @starting_page
    find(".num-annotations-badge").should have_content("2")   # there is a user and an admin annotations
    disable_user(user_login)

    visit @starting_page
    find(".num-annotations-badge").should have_content("1")   # the user annotation is not visible
    page.should have_content('Guy in the background looking sideways') #admin annotation, still there
    page.should_not have_content('air intake?') # user annotation, now hidden
  end
  
  it "should show the number of annotations in an image and allow logged in users to add a new one" do
    login_as(user_login)
    visit @starting_page
    should_allow_annotations    
    find(".num-annotations-badge").should have_content("2")     
    page.should have_content('Guy in the background looking sideways')
    page.should have_content('air intake?')
  end

  it "should not show annotations link to a non-logged in user when there are no annotations" do
    visit catalog_path('xf058ys1313')
    page.should_not have_css('#view_annotations_link')
  end
  
  it "should add/update the annotations to the right field in solr when adding/updating annotations" do
    druid='dd482qk0417'
    
    # find the solr doc and confirm there is no annotation listed
    item=SolrDocument.find(druid)
    item['annotations_tsim'].should be_nil
  
    # create an annotation
    comment1='some comment'
    user_account=User.find_by_username(user_login)
    annotation1=Annotation.create(:druid=>druid,:text=>comment1,:json=>'{a bunch of json would go here}',:user_id=>user_account.id)

    # confirm that solr has been updated
    item=SolrDocument.find(druid)
    item['annotations_tsim'].should == [comment1]
    
    comment2='second comment'
    # create the second annotation
    annotation2=Annotation.create(:druid=>druid,:text=>comment2,:json=>'{a bunch of json would go here}',:user_id=>user_account.id)

    # confirm that solr has been updated
    item=SolrDocument.find(druid)
    item['annotations_tsim'].should == [comment1,comment2]
    
    updated_comment1='changed my mind'
    # update the first annotation
    annotation1.text=updated_comment1
    annotation1.save

    # confirm that solr has been updated
    item=SolrDocument.find(druid)
    item['annotations_tsim'].should == [updated_comment1,comment2]
    
  end

  it "should remove the annotation from the right field in solr when destroying an annotation" do

     druid='yt907db4998'
     original_annotation_from_fixture='Nazi symbol'
     
     # find the solr doc and confirm there is no annotation listed
     item=SolrDocument.find(druid)
     item['annotations_tsim'].should == [original_annotation_from_fixture]

     # create an annotation
     comment='some comment'
     user_account=User.find_by_username(user_login)
     annotation=Annotation.create(:druid=>druid,:text=>comment,:json=>'{a bunch of json would go here}',:user_id=>user_account.id)

     # confirm that solr has been updated
     item=SolrDocument.find(druid)
     item['annotations_tsim'].should == [original_annotation_from_fixture,comment]

     # delete the annotation
     annotation.destroy

     # confirm that solr has been updated
     item=SolrDocument.find(druid)
     item['annotations_tsim'].should == [original_annotation_from_fixture]

   end

  it "should allow a curator to remove an annonation entered by someone else." do
    druid='yt907db4998'
    original_annotation_from_fixture='Nazi symbol'
    item_page=catalog_path(druid)
    logout

    #ensure we only have the expected orginial
    item=SolrDocument.find(druid)
    item['annotations_tsim'].should == [original_annotation_from_fixture]


    # create an annotation
     comment='The rain in spain falls mostly on the plain.'
     user_account=User.find_by_username(curator_login)
     annotation=Annotation.create(:druid=>druid,:text=>comment,:json=>'{"src":"https://stacks.stanford.edu/image/yt907db4998/2011-023DUG-3.0_0017_thumb","shapes":[{"type":"rect","geometry":{"x":0.5223880597014925,"width":0.19651741293532343,"y":0.4075471698113208,"height":0.1132075471698113}}],"context":"http://127.0.0.1:3000/catalog/yt907db4998","editable":true,"username":"me","updated_at":"September 10, 2013","id":1045387672}',:user_id=>user_account.id) 

     # confirm that solr has been updated
     item=SolrDocument.find(druid)
     item['annotations_tsim'].should == [original_annotation_from_fixture,comment]

     #go the page as an admin
     logout
     login_as(admin_login)
     visit item_page
     
     #Individual annotations have long id strings on them that make them unique, so grab the parent and then look for content
     anno_parent = page.find('#all-annotations')
     anno_parent.all('div').each do |d|
          if d.has_content?(comment)
              d.click_button('Remove')
          end
     end

     #all_anno = page.all(:css, '#annotation_')
     #all_anno.each do |a|
     #  if a.has_content?(comment)
     #   within(a) do
     #      a.click_button('Remove')
     #   end
     #  end 
     #end
     
     #end the comment has been removed
     item=SolrDocument.find(druid)
     item['annotations_tsim'].should == [original_annotation_from_fixture]
       
   
   end 

    
end

require 'spec_helper'

describe("Item Visibility",:type=>:request,:integration=>true) do

  before :each do
    @hidden_druid='bb004bn8654'
    @default_visible_druid='yt907db4998'
    @visible_druid='xf058ys1313'
    @hidden_druid_path=catalog_path(@hidden_druid)
    @nadig_collection_druid='kz071cg8658'
    @nadig_collection_path=catalog_path(@nadig_collection_druid)
  end
  
  it "should update image visibility" do
    item1=Item.where(:druid=>@hidden_druid)
    item1.size.should == 1
    doc1=SolrDocument.find(@hidden_druid)
    doc1.visibility_value.should == 0
    doc1.visibility.should == :hidden
    doc1.visibility=:visible
    doc1.save
    doc1=SolrDocument.find(@hidden_druid)
    doc1.visibility_value.should == 1
    doc1.visibility.should == :visible
    item1=Item.where(:druid=>@hidden_druid)
    item1.size.should == 1
    item1.first.visibility.should == :visible
    doc1=SolrDocument.find(@hidden_druid)
    doc1.visibility=:hidden
    doc1.save
    item1=Item.where(:druid=>@hidden_druid)
    item1.size.should == 1
    item1.first.visibility.should == :hidden
    
    doc2=SolrDocument.find(@visible_druid)
    doc2.visibility_value.should == ""
    doc2.visibility.should == :visible
    doc2.visibility=:hidden
    doc2.save
    doc2=SolrDocument.find(@visible_druid)
    doc2.visibility_value.should == 0
    doc2.visibility.should == :hidden

    doc3=SolrDocument.find(@default_visible_druid)
    doc3.visibility_value.should == 1
    doc3.visibility.should == :visible

    reindex_solr_docs([@hidden_druid,@visible_druid])    
  end
  
  it "should not show the visibility facet to non-curators" do
    visit root_path
    page.should_not have_content("Visibility Hidden 1")
    login_as(user_login)
    visit root_path
    page.should_not have_content("Visibility Hidden 1")
    login_as(curator_login)
    page.should have_content("Visibility Hidden 1")
  end
  
  it "should not show hidden items to non-logged in or regular users" do
    should_deny_access(@hidden_druid_path)
    login_as(user_login)
    should_deny_access(@hidden_druid_path)
    visit all_collections_path
    page.should have_content("The David Nadig Collection of The Revs Institute (14 items)")
    visit @nadig_collection_path
    page.should have_content("14 items")
  end

  it "should show hidden items to curators and admins" do
    logins=[curator_login,admin_login]
    logins.each do |user|
      login_as(user)
      visit @hidden_druid_path
      page.should have_content("Bryar 250 Trans-American:10")
      page.should have_content("Hidden")
      visit all_collections_path
      page.should have_content("The David Nadig Collection of The Revs Institute (15 items)")
      visit @nadig_collection_path
      page.should have_content("15 items")
      logout
    end
  end  
  
end
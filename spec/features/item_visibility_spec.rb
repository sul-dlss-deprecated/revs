require 'spec_helper'

describe("Item Visibility",:type=>:request,:integration=>true) do

  before :each do
    @hidden_druid='bb004bn8654'
    @default_visible_druid='yt907db4998'
    @visible_druid='xf058ys1313'
    @hidden_druid_path=item_path((@hidden_druid)
    @nadig_collection_druid='kz071cg8658'
    @nadig_collection_path=item_path((@nadig_collection_druid)
  end

  it "should update image visibility" do
    item1=Item.where(:druid=>@hidden_druid)
    expect(item1.size).to eq 1
    doc1=SolrDocument.find(@hidden_druid)
    expect(doc1.visibility_value).to eq(0)
    expect(doc1.visibility).to eq :hidden
    doc1.visibility=:visible
    doc1.save
    doc1=SolrDocument.find(@hidden_druid)
    expect(doc1.visibility_value).to eq 1
    expect(doc1.visibility).to eq :visible
    item1=Item.where(:druid=>@hidden_druid)
    expect(item1.size).to eq 1
    expect(item1.first.visibility).to eq :visible
    doc1=SolrDocument.find(@hidden_druid)
    doc1.visibility=:hidden
    doc1.save
    item1=Item.where(:druid=>@hidden_druid)
    expect(item1.size).to eq 1
    expect(item1.first.visibility).to eq :hidden

    doc2=SolrDocument.find(@visible_druid)
    expect(doc2.visibility_value).to eq ""
    expect(doc2.visibility).to eq :visible
    doc2.visibility=:hidden
    doc2.save
    doc2=SolrDocument.find(@visible_druid)
    expect(doc2.visibility_value).to eq 0
    expect(doc2.visibility).to eq :hidden

    doc3=SolrDocument.find(@default_visible_druid)
    expect(doc3.visibility_value).to eq 1
    expect(doc3.visibility).to eq :visible

    reindex_solr_docs([@hidden_druid,@visible_druid])
  end

  it "should not show the visibility facet to non-curators" do
    visit root_path
    expect(page).not_to have_content("Visibility")
    login_as(user_login)
    visit root_path
    expect(page).not_to have_content("Visibility")
    login_as(curator_login)
    expect(page).to have_content("Visibility")
  end

  it "should not show hidden items to non-logged in or regular users" do
    should_deny_access(@hidden_druid_path)
    login_as(user_login)
    should_deny_access(@hidden_druid_path)
    visit all_collections_path
    expect(page).to have_content('The David Nadig Collection of The Revs Institute')
    expect(page).to have_content('Revs Institute® Archives')
    expect(page).to have_content('14 items')
    visit @nadig_collection_path
    expect(page).to have_content('14 items')
  end

  it "should show hidden items to curators and admins" do
    logins=[curator_login,admin_login]
    logins.each do |user|
      login_as(user)
      visit @hidden_druid_path
      expect(page).to have_content('Bryar 250 Trans-American:10')
      expect(page).to have_content('Hidden')
      visit all_collections_path
      expect(page).to have_content('The David Nadig Collection of The Revs Institute')
      expect(page).to have_content('Revs Institute® Archives')
      expect(page).to have_content('15 items')
      visit @nadig_collection_path
      expect(page).to have_content('15 items')
      logout
    end
  end

end

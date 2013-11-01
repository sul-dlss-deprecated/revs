require 'spec_helper'

describe("Item Visibility",:type=>:request,:integration=>true) do

  before :each do
    @hidden_druid='bb004bn8654'
    @hidden_druid_path=catalog_path(@hidden_druid)
    @nadig_collection_druid='kz071cg8658'
    @nadig_collection_path=catalog_path(@nadig_collection_druid)
  end
  
  it "should not show hidden items to non-logged in or regular users" do
    should_deny_access(@hidden_druid_path)
    login_as(user_login)
    should_deny_access(@hidden_druid_path)
    visit all_collections_path
    page.should have_content("The David Nadig Collection of the Revs Institute (14 items)")
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
      page.should have_content("The David Nadig Collection of the Revs Institute (15 items)")
      visit @nadig_collection_path
      page.should have_content("15 items")
      logout
    end
  end  
  
end
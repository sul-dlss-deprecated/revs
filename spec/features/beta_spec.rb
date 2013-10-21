require 'spec_helper'

describe("Beta Users Only",:type=>:request,:integration=>true) do

  before :each do
    Revs::Application.config.restricted_beta=true # for these tests, let's make sure we restrict access to beta tests only
  end

  after :each do
    Revs::Application.config.restricted_beta=false # revert back to beta test off
  end
  
  it "should not let us visit an item detail page if we are not logged in" do 
    should_deny_access_for_beta(catalog_path('yt907db4998'))
  end

  it "should not let us visit an item detail page if we are logged in but not part of the beta" do 
    login_as user_login
    should_deny_access_for_beta(catalog_path('yt907db4998'))
    logout
  end

  it "should let us visit an item detail page if we are logged and part of the beta" do 
    login_as beta_login
    visit catalog_path('jg267fg4283')
    find('.show-document-title').should have_content('Untitled')  
    logout  
  end  

  it "should let us visit an item detail page if we are logged in as a sunet user" do 
    visit webauth_login_path
    visit catalog_path('jg267fg4283')
    find('.show-document-title').should have_content('Untitled')    
    logout
  end  
  
end

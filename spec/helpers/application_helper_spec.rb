require "spec_helper"

class ApplicationHelperTester
  include ApplicationHelper  
end

describe ApplicationHelper do
  
  before :each do 
    @app=ApplicationController.new # this is a helper_method from the application controller
    @app_helper=ApplicationHelperTester.new
  end

  it "should have the correct application_name" do
    @app.application_name.should == "Revs Digital Library"
  end
  
  it "should format years correctly" do
    @app_helper.format_years([1955]).should == '1955'
    @app_helper.format_years([1955,1956,1957,1982]).should == '1955-1957, 1982'
    @app_helper.format_years([1955,1982]).should == '1955, 1982'
    @app_helper.format_years([1955,1956,1957,1958]).should == '1955-1958'
    @app_helper.format_years([1955,1956]).should == '1955-1956'
    @app_helper.format_years([1956,1955]).should == '1955-1956'
    @app_helper.format_years([1982,1981,1957,1958,1959,1999]).should == '1957-1959, 1981-1982, 1999'
  end
  
end
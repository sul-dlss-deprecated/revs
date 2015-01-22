require "rails_helper"

class ApplicationHelperTester
  include ApplicationHelper  
end

describe ApplicationHelper do

  before :each do 
    @app=ApplicationController.new # this is a helper_method from the application controller
    @app_helper=ApplicationHelperTester.new
  end

  it "should have the correct application_name" do
    expect(@app.application_name).to eq("Revs Digital Library")
  end
  
  it "should format years correctly" do
    expect(@app_helper.format_years([1955])).to eq('1955')
    expect(@app_helper.format_years([1955,1956,1957,1982])).to eq('1955-1957, 1982')
    expect(@app_helper.format_years([1955,1982])).to eq('1955, 1982')
    expect(@app_helper.format_years([1955,1956,1957,1958])).to eq('1955-1958')
    expect(@app_helper.format_years([1955,1956])).to eq('1955-1956')
    expect(@app_helper.format_years([1956,1955])).to eq('1955-1956')
    expect(@app_helper.format_years([1982,1981,1957,1958,1959,1999])).to eq('1957-1959, 1981-1982, 1999')
  end
  
end
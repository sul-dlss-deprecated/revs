require "spec_helper"

describe ApplicationHelper do
  describe "Blacklight overrides" do
    it "should have the correct application_name" do
      @app=ApplicationController.new # this is a helper_method from the application controller
      @app.application_name.should == "Revs Digital Library"
    end
  end
  
end
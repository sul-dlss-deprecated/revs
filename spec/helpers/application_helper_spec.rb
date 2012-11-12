require "spec_helper"

describe ApplicationHelper do
  describe "Blacklight overrides" do
    it "should have the correct application_name" do
      application_name.should == "Revs Digital Library"
    end
  end
  
end
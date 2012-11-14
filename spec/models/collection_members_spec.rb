require "spec_helper"

describe CollectionMembers do
  before(:all) do
    @response = {"response" => {"numFound" => "3",
                               "docs" => [{:id=>"12345"}, {:id=>"54321"}]
                               }
                }
  end
  it "should get the numFound from the solr response " do
    CollectionMembers.new(@response).total_members.should == @response["response"]["numFound"]
  end
  it "shuold turn the docs array from the solr response into an array of SolrDocuments" do
    members = CollectionMembers.new(@response)
    members.documents.each do |document|
      document.should be_a SolrDocument
    end
    members.documents.length.should == @response["response"]["docs"].length
  end
  
  describe "enumerable emthods" do
    it "should respond to each properly" do
      members = []
      CollectionMembers.new(@response).each do |m|
        members << m
      end
      members.length.should == @response["response"]["docs"].length
    end
    it "should respond to other enumerable methods" do
      CollectionMembers.new(@response).map{|m| m }.length.should == @response["response"]["docs"].length
      CollectionMembers.new(@response).find {|m| m[:id] !=  @response["response"]["docs"].first[:id] }.should be_a SolrDocument
    end
  end

end
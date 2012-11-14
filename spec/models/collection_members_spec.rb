require "spec_helper"

describe CollectionMembers do
  before(:all) do
    @response = {"response" => {"numFound" => "3",
                               "docs" => [{:id=>"12345", :id=>"54321"}]
                               }
                }
  end
  it "should get the numFound from the solr response " do
    CollectionMembers.new(@response).total.should == @response["response"]["numFound"]
  end
  it "shuold turn the docs array from the solr response into an array of SolrDocuments" do
    members = CollectionMembers.new(@response)
    members.documents.each do |document|
      document.should be_a SolrDocument
    end
    members.documents.length.should == @response["response"]["docs"].length
  end
end
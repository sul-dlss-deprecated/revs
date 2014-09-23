require "rails_helper"

describe CollectionMembers do
  before(:all) do
    @response = {"response" => {"numFound" => "3",
                               "docs" => [{:id=>"12345"}, {:id=>"54321"}]
                               }
                }
  end
  it "should get the numFound from the solr response " do
    expect(CollectionMembers.new(@response).total_members).to eq(@response["response"]["numFound"])
  end
  it "shuold turn the docs array from the solr response into an array of SolrDocuments" do
    members = CollectionMembers.new(@response)
    members.documents.each do |document|
      expect(document).to be_a SolrDocument
    end
    expect(members.documents.length).to eq(@response["response"]["docs"].length)
  end
  
  describe "enumerable emthods" do
    it "should respond to each properly" do
      members = []
      CollectionMembers.new(@response).each do |m|
        members << m
      end
      expect(members.length).to eq(@response["response"]["docs"].length)
    end
    it "should respond to other enumerable methods" do
      expect(CollectionMembers.new(@response).map{|m| m }.length).to eq(@response["response"]["docs"].length)
      expect(CollectionMembers.new(@response).find {|m| m[:id] !=  @response["response"]["docs"].first[:id] }).to be_a SolrDocument
    end
  end

end
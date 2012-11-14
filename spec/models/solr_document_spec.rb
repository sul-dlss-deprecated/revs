require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    doc.should be_a SolrDocument
    doc[:id].should == "12345"
    doc.should respond_to :export_formats
  end
  
  describe "collections" do
    it "should define themselves as such when they have the correct fields" do
      SolrDocument.new({:id=>"12345"}).collection?.should be_false
      SolrDocument.new({:id=>"12345", :format => "Collection"}).collection?.should be_true
    end
    describe "collection members" do
      it "should define themselves as such when they have the correct fields" do
        SolrDocument.new({:id => "12345"}).collection_member?.should be_false
        SolrDocument.new({:"is_member_of_display" => "collection-1"}).collection_member?.should be_true
      end
      it "should memoize the solr request" do
        response = {"response" => {"numFound" => 3, "docs" => [{:id=>"1234", :id =>"4321"}]}}
        solr = mock("solr")
        solr.should_receive(:select).with({:fq => "is_member_of_display:\"collection-1\"", :rows => "20"}).once.and_return(response)
        Blacklight.should_receive(:solr).and_return(solr)
        doc = SolrDocument.new({:id => "collection-1", :format => "Collection"})
        5.times do
          doc.collection_members
        end
      end
      it "should return nil if the SolrDocument is not a collection" do
        SolrDocument.new(:id=>"1235").collection_members.should be nil
      end
    end
  end
end
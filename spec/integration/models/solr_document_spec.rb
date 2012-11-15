require "spec_helper"

describe SolrDocument, :integration => true do
  describe "collections" do
    describe "collection" do
      it "should return a the parend document as a SolrDocument" do
        doc = SolrDocument.new({:id => "wp220cw0167", :is_member_of => ["nt028fd5773"]})
        doc.collection.should_not be_blank
        doc.collection.should be_a SolrDocument
        doc.collection.collection?.should be_true
        doc.collection[:id].should == "nt028fd5773"
      end
    end
    describe "collection_members" do
      it "should return a collection members class with an array of SolrDocument" do
        doc = SolrDocument.new({:id => "nt028fd5773", :format => "Collection"})
        doc.collection_members.should be_a CollectionMembers
        doc.collection_members.should_not be_blank
        doc.collection_members.total_members.should > 0
        doc.collection_members.documents.should be_a Array
        doc.collection_members.documents.each do |member|
          member.should be_a SolrDocument
        end
      end
    end
  end
end
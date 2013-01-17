require "spec_helper"

describe SolrDocument, :integration => true do
  describe "collections" do
    describe "collection" do
      it "should return a the parend document as a SolrDocument" do
        doc = SolrDocument.new({:id => "wp220cw0167", :is_member_of_ssim => ["nt028fd5773"]})
        doc.collection.should_not be_blank
        doc.collection.should be_a SolrDocument
        doc.collection.collection?.should be_true
        doc.collection[:id].should == "nt028fd5773"
      end
    end
    describe "collection_members" do
      it "should return a collection members class with an array of SolrDocument" do
        doc = SolrDocument.new({:id => "nt028fd5773", :format_ssim => "collection"})
        doc.collection_members.should be_a CollectionMembers
        doc.collection_members.should_not be_blank
        doc.collection_members.total_members.should be > 0
        doc.collection_members.documents.should be_a Array
        doc.collection_members.documents.each do |member|
          member.should be_a SolrDocument
        end
      end
    end
    describe "collection_siblings" do
      it "should return a collection members class with an array of SolrDocuments" do
        doc = SolrDocument.new({:id => "nt028fd5773", :is_member_of_ssim => ["nt028fd5773"]})
        doc.collection_siblings.should be_a CollectionMembers
        doc.collection_siblings.should_not be_blank
        doc.collection_siblings.total_members.should be > 0
        doc.collection_siblings.documents.should be_a Array
        doc.collection_siblings.documents.each do |sibling|
          sibling.should be_a SolrDocument
        end
      end
    end
    describe "all_collections" do
      it "shold return an array of collection SolrDocuments" do
        document = SolrDocument.new
        document.all_collections.length.should be > 0
        document.all_collections.each do |doc|
          doc.collection?.should be_true
          doc.should be_a SolrDocument
        end
      end
    end
    
  end
end
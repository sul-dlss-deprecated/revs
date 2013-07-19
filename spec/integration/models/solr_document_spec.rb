require "spec_helper"

describe SolrDocument, :integration => true do
  
  describe "metadata_editing" do
    
    it "should apply bulk updates to solr and editstore when update method is called directly" do

      druids_to_edit=%w{nn572km4370 kn529wc4372}
      new_value='newbie!'
      field_to_edit='title_tsi'
      old_values={}
      
      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        doc.title.should_not == new_value
        old_values[druid] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
        Editstore::Change.where(:new_value=>new_value,:old_value=>doc.title,:druid=>druid).size.should == 0
      end
      
      params_hash={:field_name=>field_to_edit, :new_value=>new_value,:selected_druids=>druids_to_edit}
      success=SolrDocument.bulk_update(params_hash)
      success.should be_true
      
      # confirm new field has been updated in solr and has correct rows in editstore database
      druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        doc.title.should == new_value
        Editstore::Change.where(:new_value=>new_value,:old_value=>old_values[druid],:druid=>druid).size.should == 1
      end
      
      # reload solr docs we changed back to their original values
      reload_solr_docs(druids_to_edit)
      
    end
    
  end
  
  describe "find method" do
    it "should return an instance of a solr document" do
      doc = SolrDocument.find('yt907db4998')
      doc.should be_a SolrDocument
      doc.title.should == 'Record 1'
    end
  end
  
  describe "collections" do
    describe "collection" do
      it "should return a the parent document as a SolrDocument" do
        doc = SolrDocument.new({:id => "yt907db4998", :is_member_of_ssim => ["wn860zc7322"]})
        doc.collection.should_not be_blank
        doc.collection.should be_a SolrDocument
        doc.collection.is_collection?.should be_true
        doc.collection[:id].should == "wn860zc7322"
      end
    end

    describe "collection_members" do
      it "should return a collection members class with an array of SolrDocument" do
        doc = SolrDocument.new({:id => "wn860zc7322", :format_ssim => "collection"})
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
        doc = SolrDocument.new({:id => "wn860zc7322", :is_member_of_ssim => ["kz071cg8658"]})
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
        SolrDocument.all_collections.length.should be == 2
        SolrDocument.all_collections.each do |doc|
          doc.is_collection?.should be_true
          doc.should be_a SolrDocument
        end
      end
    end
    
  end
  
end
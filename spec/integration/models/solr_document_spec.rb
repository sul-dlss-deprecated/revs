require "spec_helper"

describe SolrDocument, :integration => true do
  
  describe "getter methods" do
    
    it "should retrieve a couple single valued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      doc.title.should == doc['title_tsi']
      doc.title.class.should == String
      doc.photographer.should == doc['photographer_ssi']
      doc.photographer.class.should == String
      doc.description.should == doc['description_tsim'].first # returns a single value even though this is a multivalued field in solr
      doc.description.class.should == String
    end

    it "should retrieve a couple single multivalued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should == doc['marque_ssim']
      doc.marque.class.should == Array
      doc.people.should == doc['people_ssim']
      doc.people.class.should == Array
    end
          
    it "should return an empty string when that value doesn't exist in the solr doc" do
      doc = SolrDocument.find('yt907db4998')
      doc['photographer_ssi'].should be_nil
      doc['model_year_ssim'].should be_nil
      doc.photographer.should == ""
      doc.model_year.should == ""
    end
    
    it "should return the default value for the title when it is not set" do
      doc = SolrDocument.find('jg267fg4283')
      doc['title_tsi'].should be_nil
      doc.title.should == 'Untitled'
      doc['title_tsi']='' # even when blank, it should still show as untitled
      doc.title.should == 'Untitled'
    end
    
  end
  
  describe "metadata_editing" do
    
    it "should apply bulk updates to solr and editstore when update method is called directly" do

      druids_to_edit=%w{nn572km4370 kn529wc4372}
      new_value='newbie!'
      field_to_edit='title'
      old_values={}
      
      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        doc.title.should_not == new_value
        old_values[druid] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
        Editstore::Change.where(:new_value=>new_value,:old_value=>doc.title,:druid=>druid).size.should == 0
      end
      
      params_hash={:attribute=>field_to_edit, :new_value=>new_value,:selected_druids=>druids_to_edit}
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
    
    it "should use editstore" do
      SolrDocument.use_editstore.should be_true
    end
    
  end
  
  describe "image priority for sorting images in a collection" do
    
    it "should indicate which is the highest priority number for a collection" do 
      collection=SolrDocument.find('wn860zc7322')
      collection.current_top_priority.should == 1
      collection.first_image.should == 'https://stacks-test.stanford.edu/image/yt907db4998/2011-023DUG-3.0_0017_thumb'
      item1=SolrDocument.find('yt907db4998')
      item1.priority.should == 1
      item2=SolrDocument.find('qb957rw1430')
      item2.priority.should == 0      
      collection.first_item.id.should == 'yt907db4998'
    end
    
    it "should set the highest priority image and have the first image be different" do
      item2=SolrDocument.find('qb957rw1430')
      item2.set_top_priority
      collection=SolrDocument.find('wn860zc7322')
      collection.current_top_priority.should == 2
      collection.first_image.should == 'https://stacks-test.stanford.edu/image/qb957rw1430/2011-023DUG-3.0_0015_thumb'
      collection.first_item.id.should == 'qb957rw1430'
      # reload document we changed
      reload_solr_docs(['qb957rw1430','yt907db4998','wn860zc7322'])
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
      
      it "should return an item's collection" do
        item=SolrDocument.find('yt907db4998')
        item.is_item?.should be_true
        item.is_collection?.should be_false
        collection=item.collection
        collection.is_collection?.should be_true
        collection.is_item?.should be_false        
        collection.id.should == 'wn860zc7322'  
      end

      it "should return a collection's items" do
        collection=SolrDocument.find('wn860zc7322')
        collection.collection_members.size.should == 2
        collection.collection_members.each {|item| item.is_item?.should be_true}
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

    describe "siblings" do
      it "should return a collection members class with an array of SolrDocuments" do
        doc = SolrDocument.new({:id => "wn860zc7322", :is_member_of_ssim => ["kz071cg8658"]})
        doc.siblings.should be_a CollectionMembers
        doc.siblings.should_not be_blank
        doc.siblings.total_members.should be > 0
        doc.siblings.documents.should be_a Array
        doc.siblings.documents.each do |sibling|
          sibling.should be_a SolrDocument
        end
      end
    end

    describe "all_images" do
      it "should return the total number of images" do
        SolrDocument.total_images.should be == 16
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
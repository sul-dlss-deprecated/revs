require "spec_helper"

describe SolrDocument, :integration => true do

  describe "rights and copyright" do
  
    it "should retrieve the default rights and copyright statements if not found in solr document" do
      doc=SolrDocument.find('bb004bn8654') # fixture with none specified
      expect(doc.use_and_reproduction).to eq("Users must contact The The Revs Institute for Automotive Research, Inc. for re-use and reproduction information.")
      expect(doc.copyright).to eq("Courtesy of the Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.")
    end

    it "should retrieve the rights and copyright statements if found in solr document" do
      doc=SolrDocument.find('td830rb1584') # fixtures with values specified
      expect(doc.use_and_reproduction).to eq("This is the use and reproduction statement - different from default.")
      expect(doc.copyright).to eq("This is the copyright statement - different from default.")
    end
    
  end
  
  describe "validation" do

    before :each do
      @doc = SolrDocument.find('yt907db4998')
    end
    
    it "should catch invalid dates" do
      expect(@doc.valid?).to be_true
      @doc.full_date = 'crap' # bad value
      expect(@doc.dirty?).to be_true
      expect(@doc.valid?).to be_false
      expect(@doc.save).to be_false      
      @doc.full_date = '5/1/2001' # this is ok
      expect(@doc.valid?).to be_true
      @doc.full_date = '' # blanks is ok
      expect(@doc.valid?).to be_true      
   end

   it "should catch invalid model years" do
     expect(@doc.valid?).to be_true
     @doc.model_year = ['crap','1961'] # bad value
     expect(@doc.dirty?).to be_true
     expect(@doc.valid?).to be_false
     expect(@doc.save).to be_false      
     @doc.model_year = '1810' # this is bad (before 1850)
     expect(@doc.valid?).to be_false   
     @doc.model_year = Date.today.year+1 # this is bad (future)
     expect(@doc.valid?).to be_false  
     @doc.model_year = 'crap' # this is bad
     expect(@doc.valid?).to be_false
     @doc.model_year = '1999' # this is ok
     expect(@doc.valid?).to be_true
     @doc.model_year = ['1959','1961'] # ok
     expect(@doc.valid?).to be_true      
     @doc.model_year_mvf = '1959|1961' # mvf ok
     expect(@doc.valid?).to be_true
     @doc.model_year_mvf = 'abc|1961' # bad
     expect(@doc.valid?).to be_false
     @doc.model_year_mvf = '1961' # ok
     expect(@doc.valid?).to be_true
     @doc.model_year = '' # blanks is ok
     expect(@doc.valid?).to be_true   
     @doc.model_year_mvf = '' # blanks is ok
     expect(@doc.valid?).to be_true        
   end
   
    it "should catch invalid years" do
      expect(@doc.valid?).to be_true
      @doc.years = ['crap','1961'] # bad value
      expect(@doc.dirty?).to be_true
      expect(@doc.valid?).to be_false
      expect(@doc.save).to be_false   
      @doc.years = '1750' # this is bad (before 1800)
      expect(@doc.valid?).to be_false   
      @doc.years = Date.today.year+1 # this is bad (future)
      expect(@doc.valid?).to be_false         
      @doc.years = 'crap' # this is bad
      expect(@doc.valid?).to be_false
      @doc.years = '1999' # this is ok
      expect(@doc.valid?).to be_true
      @doc.years = ['1959','1961'] # ok
      expect(@doc.valid?).to be_true      
      @doc.years_mvf = '1959|1961' # mvf ok
      expect(@doc.valid?).to be_true
      @doc.years_mvf = 'abc|1961' # bad
      expect(@doc.valid?).to be_false
      @doc.years_mvf = '1961' # ok
      expect(@doc.valid?).to be_true
      @doc.years = '' # blanks is ok
      expect(@doc.valid?).to be_true   
      @doc.years_mvf = '' # blanks is ok
      expect(@doc.valid?).to be_true         
   end
      
  end
    
  describe "metadata_editing" do
    
    before :each do

      @field_to_edit='title'
      @solr_field=SolrDocument.field_mappings[@field_to_edit.to_sym][:field]
      @druids_to_edit=%w{nn572km4370 kn529wc4372}
      @old_values={}
      @new_value='newbie!'
      @user=User.last

    end

    it "should apply bulk replace updates to solr and editstore when update method is called directly for an update operation" do
      
      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      @druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        expect(doc.title).not_to eq(@new_value)
        @old_values[druid] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
        expect(Editstore::Change.where(:new_value=>@new_value,:old_value=>doc.title,:field=>@solr_field,:druid=>druid).size).to eq(0)
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>@user.id).size).to eq(0)
      end
      
      params_hash={:attribute=>@field_to_edit, :action=>'update', :new_value=>@new_value,:selected_druids=>@druids_to_edit}
      success=SolrDocument.bulk_update(params_hash,@user)
      expect(success).to be_true
      
      # confirm new field has been updated in solr and has correct rows in editstore database
      @druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        expect(doc.title).to eq(@new_value)
        expect(Editstore::Change.where(:new_value=>@new_value,:old_value=>@old_values[druid],:field=>@solr_field,:druid=>druid).size).to eq(1)
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>@user.id).size).to eq(1)
      end
      
      # reindex solr docs we changed back to their original values
      reindex_solr_docs(@druids_to_edit)
      
    end
 
     it "should apply bulk updates to solr and editstore when update method is called directly for a search and replace operation for a single value field" do
      
      @druid_that_should_change='nn572km4370'
      @druid_that_should_not_change='kn529wc4372'
      @search_value='Thompson Raceway, May 1'

      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      doc=SolrDocument.find(@druid_that_should_change) # this druid should change
      expect(doc.title).not_to eq(@new_value)
      expect(doc.title).to eq(@search_value)
      @old_values[@druid_that_should_change] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
      expect(Editstore::Change.where(:new_value=>@new_value,:old_value=>doc.title,:field=>@solr_field,:druid=>@druid_that_should_change).size).to eq(0)
      expect(ChangeLog.where(:druid=>@druid_that_should_change,:operation=>'metadata update',:user_id=>@user.id).size).to eq(0)

      doc=SolrDocument.find(@druid_that_should_not_change) # this druid should change
      expect(doc.title).not_to eq(@new_value)
      expect(doc.title).not_to eq(@search_value)
      @old_values[@druid_that_should_not_change] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
      expect(Editstore::Change.where(:new_value=>@new_value,:old_value=>doc.title,:field=>@solr_field,:druid=>@druid_that_should_not_change).size).to eq(0)
      expect(ChangeLog.where(:druid=>@druid_that_should_not_change,:operation=>'metadata update',:user_id=>@user.id).size).to eq(0)

      params_hash={:attribute=>@field_to_edit, :new_value=>@new_value, :search_value=>@search_value, :action=>'replace', :selected_druids=>@druids_to_edit}
      success=SolrDocument.bulk_update(params_hash,@user)
      expect(success).to be_true
      
      # confirm new field has been updated in solr and has correct rows in editstore database for only the one record that matches
      doc=SolrDocument.find(@druid_that_should_change) # this druid should change
      expect(doc.title).to eq(@new_value)
      expect(Editstore::Change.where(:new_value=>@new_value,:operation=>:update,:field=>@solr_field,:druid=>@druid_that_should_change).size).to eq(1)
      expect(ChangeLog.where(:druid=>@druid_that_should_change,:operation=>'metadata update',:user_id=>@user.id).size).to eq(1)
 
      # confirm new field has been updated in solr and has correct rows in editstore database for only the one record that matches
      doc=SolrDocument.find(@druid_that_should_not_change) # this druid should change
      expect(doc.title).not_to eq(@new_value)
      expect(doc.title).to eq(@old_values[@druid_that_should_not_change])
      expect(Editstore::Change.where(:new_value=>@new_value,:operation=>:update,:field=>@solr_field,:druid=>@druid_that_should_not_change).size).to eq(0)
      
      expect(ChangeLog.where(:druid=>@druid_that_should_not_change,:operation=>'metadata update',:user_id=>@user.id).size).to eq(0)
      # reindex solr docs we changed back to their original values
      reindex_solr_docs([@druid_that_should_change])
      
    end   

     it "should apply bulk updates to solr and editstore when update method is called directly for a remove operation" do
      
      # confirm new field doesn't exist in solr and rows don't exist yet in editstore database
      @druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        expect(doc.title).not_to eq('Untitled')
        @old_values[druid] =  doc.title # store old values in hash so we can use it later in the test when checking the editstore database
        expect(Editstore::Change.where(:new_value=>'',:operation=>:delete,:field=>@solr_field,:druid=>druid).size).to eq(0)
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>@user.id).size).to eq(0)
      end
      
      params_hash={:attribute=>@field_to_edit, :action=>'remove', :selected_druids=>@druids_to_edit}
      success=SolrDocument.bulk_update(params_hash,@user)
      expect(success).to be_true
      
      # confirm new field has been updated in solr and has correct rows in editstore database
      @druids_to_edit.each do |druid|
        doc=SolrDocument.find(druid)
        expect(doc.title).to eq('Untitled')
        expect(Editstore::Change.where(:new_value=>'',:operation=>:delete,:field=>@solr_field,:druid=>druid).size).to eq(1)
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>@user.id).size).to eq(1)
      end
      
      # reindex solr docs we changed back to their original values
      reindex_solr_docs(@druids_to_edit)
      
    end   

    it "should use editstore" do
      expect(SolrDocument.use_editstore).to be_true
    end
  
  end

    describe "update_date_fields callback methods" do
      
      it "should automatically set the year field and single year solr field when a full date is set" do
        druid='zp006sp7532'

        user=User.last
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>user.id).size).to eq(0)
       
        doc=SolrDocument.find(druid)
        expect(doc.years).to eq([1969]) # current year value
        expect(doc.single_year).to eq(1969) # check the solr fields        
        expect(doc.full_date).to eq('') # current full date value
        doc.full_date='5/6/1999' # set a new full date
        expect(doc.years).to eq([1969]) # year hasn't be set yet, since we haven't saved
        doc.save(:user=>user) # now let's save it
        
        expect(ChangeLog.where(:druid=>druid,:operation=>'metadata update',:user_id=>user.id).size).to eq(1)
        
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.years).to eq([1999]) # year has now been updated
        expect(reload_doc.single_year).to eq(1999) # check the solr fields
        reindex_solr_docs(druid)
      end

      it "should automatically remove the single year field when multiple years are set" do
        druid='zp006sp7532'        
        doc=SolrDocument.find(druid)
        expect(doc.years).to eq([1969]) # current year value
        expect(doc.single_year).to eq(1969) # check the solr fields        
        expect(doc.full_date).to eq('') # current full date value
        doc.years_mvf='2000|2001' # set multiple years
        doc.save # now let's save it
        
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.years).to eq([2000,2001]) # years has now been updated
        expect(reload_doc.single_year).to eq('')
        reindex_solr_docs(druid)
      end

      it "should automatically set the single year field when a new single year is set" do
        druid='zp006sp7532'        
        doc=SolrDocument.find(druid)
        expect(doc.years).to eq([1969]) # current year value
        expect(doc.single_year).to eq(1969) # check the solr fields        
        expect(doc.full_date).to eq('') # current full date value
        doc.years_mvf='1989' # set new single year
        doc.save # now let's save it
        
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.years).to eq([1989]) # years has now been updated
        expect(reload_doc.single_year).to eq(1989) # single year field is updated
        reindex_solr_docs(druid)
      end
      
      it "should clear out the full date field if a new year is set" do
        druid='td830rb1584'
        doc=SolrDocument.find(druid)
        expect(doc.full_date).to eq('5/1/1955') # current full date
        doc.years='2002'
        doc.save
        
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.full_date).to eq('') # full date is now gone
        expect(reload_doc.single_year).to eq(2002)
        reindex_solr_docs(druid)
      end
    
      it "should correctly remove values from a solr document" do
        druid='zp006sp7532'
        doc=SolrDocument.find(druid)
        expect(doc[:pub_year_isim]).to eq([1969])
        expect(doc[:pub_year_single_isi]).to eq(1969)
        doc.immediate_remove(:pub_year_single_isi)
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc[:pub_year_single_isi]).to be_nil
        reindex_solr_docs(druid)
      end

      it "should clear out the multivalued year field if the single valued year field is removed and should clear out the single value year field if the multivalued year field is removed" do
        druid='zp006sp7532'
        doc=SolrDocument.find(druid)
        expect(doc.years).to eq([1969]) # current year value
        expect(doc.single_year).to eq(1969)
        doc.years=''
        doc.save
        
        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.full_date).to eq('') # no full date
        expect(reload_doc.years).to eq('') # no multivalued year
        expect(reload_doc.single_year).to eq('') # no single year

        reindex_solr_docs(druid)

        doc=SolrDocument.find(druid)
        expect(doc.years).to eq([1969]) # current year value
        doc.single_year = '' # set single year to blank
        doc.save

        reload_doc=SolrDocument.find(druid)
        expect(reload_doc.full_date).to eq('') # no full date
        expect(reload_doc.single_year).to eq('') # no single year
        expect(reload_doc.years).to eq('') # no multivalued year
        reindex_solr_docs(druid)
        
      end
      
    end
      
  describe "image priority for sorting images in a collection" do
    
    it "should indicate which is the highest priority number for a collection" do 
      collection=SolrDocument.find('wn860zc7322')
      expect(collection.current_top_priority).to eq(1)
      expect(collection.first_image).to eq('https://stacks.stanford.edu/image/yt907db4998/2011-023DUG-3.0_0017_thumb')
      item1=SolrDocument.find('yt907db4998')
      expect(item1.priority).to eq(1)
      item2=SolrDocument.find('qb957rw1430')
      expect(item2.priority).to eq(0)      
      expect(collection.first_item.id).to eq('yt907db4998')
    end
    
    it "should set the highest priority image and have the first image be different" do
      item2=SolrDocument.find('qb957rw1430')
      item2.set_top_priority
      collection=SolrDocument.find('wn860zc7322')
      expect(collection.current_top_priority).to eq(2)
      expect(collection.first_image).to eq('https://stacks.stanford.edu/image/qb957rw1430/2011-023DUG-3.0_0015_thumb')
      expect(collection.first_item.id).to eq('qb957rw1430')
      # reindex document we changed
      reindex_solr_docs(['qb957rw1430','yt907db4998','wn860zc7322'])
    end

    it "should know if it is the highest priority item in its collection" do
      item1=SolrDocument.find('yt907db4998')
      expect(item1.priority).to eq(1)
      item2=SolrDocument.find('qb957rw1430')
      expect(item2.priority).to eq(0)
      expect(item1.top_priority?).to eq(true)
      expect(item2.top_priority?).to eq(false)
    end

  end
  
  describe "collections" do
    describe "collection" do
      it "should return a the parent document as a SolrDocument" do
        doc = SolrDocument.new({:id => "yt907db4998", :is_member_of_ssim => ["wn860zc7322"]})
        expect(doc.collection).not_to be_blank
        expect(doc.collection).to be_a SolrDocument
        expect(doc.collection.is_collection?).to be_true
        expect(doc.collection[:id]).to eq("wn860zc7322")
      end
      
      it "should return an item's collection" do
        item=SolrDocument.find('yt907db4998')
        expect(item.is_item?).to be_true
        expect(item.is_collection?).to be_false
        collection=item.collection
        expect(collection.is_collection?).to be_true
        expect(collection.is_item?).to be_false        
        expect(collection.id).to eq('wn860zc7322')  
      end

      it "should return a collection's items" do
        collection=SolrDocument.find('wn860zc7322')
        expect(collection.collection_members.size).to eq(2)
        collection.collection_members.each {|item| expect(item.is_item?).to be_true}
      end
      
    end

    describe "collection_members" do
      it "should return a collection members class with an array of SolrDocument" do
        doc = SolrDocument.new({:id => "wn860zc7322", :format_ssim => "collection"})
        expect(doc.collection_members).to be_a CollectionMembers
        expect(doc.collection_members).not_to be_blank
        expect(doc.collection_members.total_members).to be > 0
        expect(doc.collection_members.documents).to be_a Array
        doc.collection_members.documents.each do |member|
          expect(member).to be_a SolrDocument
        end
      end
    end

    describe "siblings" do
      it "should return a collection members class with an array of SolrDocuments" do
        doc = SolrDocument.new({:id => "wn860zc7322", :is_member_of_ssim => ["kz071cg8658"]})
        expect(doc.siblings).to be_a CollectionMembers
        expect(doc.siblings).not_to be_blank
        expect(doc.siblings.total_members).to be > 0
        expect(doc.siblings.documents).to be_a Array
        doc.siblings.documents.each do |sibling|
          expect(sibling).to be_a SolrDocument
        end
      end
    end

    describe "all_images" do
      it "should return the total number of images" do
        expect(SolrDocument.total_images).to eq(16) # default is visible
        expect(SolrDocument.total_images(:visible)).to eq(16)
        expect(SolrDocument.total_images(:hidden)).to eq(1)
        expect(SolrDocument.total_images(:all)).to eq(17)
      end
    end
    
    describe "all_collections" do
      it "shold return an array of collection SolrDocuments" do
        expect(SolrDocument.all_collections.length).to eq(2)
        SolrDocument.all_collections.each do |doc|
          expect(doc.is_collection?).to be_true
          expect(doc).to be_a SolrDocument
        end
      end
    end
    
  end
  
end
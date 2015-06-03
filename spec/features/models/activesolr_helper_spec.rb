require "rails_helper"

describe ActivesolrHelper, :integration => true do
  
  describe "class level methods" do 
     
    it "find method should return an instance of a solr document that is an item" do
      doc = SolrDocument.find('yt907db4998')
      expect(doc).to be_a SolrDocument
      expect(doc.title).to eq('Record 1')
      expect(doc.is_item?).to be_truthy
    end
  
    it "should have the correct mvf field marker" do
      expect(SolrDocument.multivalued_field_marker).to eq('_mvf')
    end
  
    it "should indicate when values are equivalent, whether arrays of regardless of type or extra leading/trailing spaces" do
      expect(SolrDocument.is_equal?(1,"1")).to be_truthy
      expect(SolrDocument.is_equal?("1","1")).to be_truthy
      expect(SolrDocument.is_equal?(["1"],"1")).to be_truthy
      expect(SolrDocument.is_equal?(["1"],1)).to be_truthy
      expect(SolrDocument.is_equal?(["abc"],"abc")).to be_truthy
      expect(SolrDocument.is_equal?("abc",["abc"])).to be_truthy
      expect(SolrDocument.is_equal?("abc",["abc","123"])).to be_falsey
      expect(SolrDocument.is_equal?([123,"abc"],["abc","123"])).to be_truthy
      expect(SolrDocument.is_equal?([123,"  abc"],["abc","123 "])).to be_truthy
    end

    it "should indicate when multivalued field values are equivalent to the solr field array equivalents" do
       expect(SolrDocument.is_equal?("1",1,true)).to be_truthy
       expect(SolrDocument.is_equal?("1","1",true)).to be_truthy
       expect(SolrDocument.is_equal?(1,"1",true)).to be_truthy
       expect(SolrDocument.is_equal?([1],"1",true)).to be_truthy
       expect(SolrDocument.is_equal?([1,2],"1 | 2",true)).to be_truthy
       expect(SolrDocument.is_equal?(['1','2'],"1 | 2",true)).to be_truthy
       expect(SolrDocument.is_equal?(['peter','paul','mary']," peter |  paul| mary",true)).to be_truthy
       expect(SolrDocument.is_equal?(['peter','paul','mary'],"peter|paul|mary",true)).to be_truthy
       expect(SolrDocument.is_equal?(['peter','paul','mary'],"peter|paul|mary",false)).to be_falsey # if we don't ask for a multivalued field comparison, this should fail

       expect(SolrDocument.is_equal?(['1','2'],["1 | 2"],true)).to be_falsey # an incoming array is not what you'd expect coming from a multivalued field

     end
    
    it "to_array should convert strings to arrays, and leave arrays alone" do
      expect(SolrDocument.to_array('test')).to eq(['test'])
      expect(SolrDocument.to_array(1)).to eq([1])
      expect(SolrDocument.to_array('')).to eq([''])
      expect(SolrDocument.to_array(nil)).to eq([nil])
      expect(SolrDocument.to_array([])).to eq([])
      expect(SolrDocument.to_array(['test'])).to eq(['test'])
      expect(SolrDocument.to_array(['test','test2'])).to eq(['test','test2'])
    end
  
    it "should return if a value is blank, either an array of blank entries or a single blank value" do
      expect(SolrDocument.blank_value?(nil)).to be_truthy
      expect(SolrDocument.blank_value?([nil])).to be_truthy
      expect(SolrDocument.blank_value?([''])).to be_truthy
      expect(SolrDocument.blank_value?(['',''])).to be_truthy
      expect(SolrDocument.blank_value?('a')).to be_falsey
      expect(SolrDocument.blank_value?(['a'])).to be_falsey    
      expect(SolrDocument.blank_value?(['a',''])).to be_falsey    
      expect(SolrDocument.blank_value?(['a',nil])).to be_falsey    
    end
  
  end

  describe "getter methods" do
      
    it "should fail with a non-configured getter" do
      doc = SolrDocument.find('jg267fg4283')
      expect { value=doc.bogus_field }.to raise_error
    end
    
    it "should retrieve a couple single valued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      expect(doc.title).to eq(doc['title_tsi'])
      expect(doc.title.class).to eq(String)
      expect(doc.photographer).to eq(doc['photographer_ssi'])
      expect(doc.photographer.class).to eq(String)
      expect(doc.description).to eq(doc['description_tsim'].first) # returns a single value even though this is a multivalued field in solr
      expect(doc.description.class).to eq(String)
      expect(doc.archive_name).to eq(doc['archive_ssi'])
      expect(doc.archive_name.class).to eq(String)
    end

    it "should retrieve a couple multivalued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      expect(doc.marque).to eq(doc['marque_ssim'])
      expect(doc.marque.class).to eq(Array)
      expect(doc.people).to eq(doc['people_ssim'])
      expect(doc.people.class).to eq(Array)
      expect(doc.collection_names).to eq(doc['collection_ssim'])
      expect(doc.collection_names.class).to eq(Array)
    end

    it "should retrieve a couple a multivalued fields correctly with a split when using the MFV syntax" do
      doc = SolrDocument.find('yh093pt9555')
      expect(doc.marque_mvf).to eq(doc['marque_ssim'].join(' | '))
      expect(doc.marque_mvf.class).to eq(String)
    end
              
    it "should return an empty string when that value doesn't exist in the solr doc" do
      doc = SolrDocument.find('yt907db4998')
      expect(doc['photographer_ssi']).to be_nil
      expect(doc['model_year_ssim']).to be_nil
      expect(doc.photographer).to eq("")
      expect(doc.model_year).to eq("")
    end
    
    it "should return the default value for the title when it is not set" do
      doc = SolrDocument.find('jg267fg4283')
      expect(doc['title_tsi']).to be_nil
      expect(doc.title).to eq('Untitled')
      doc['title_tsi']='' # even when blank, it should still show as untitled
      expect(doc.title).to eq('Untitled')
    end
    
  end
  
  describe "setter methods" do
    
    it "should fail with a non-configured setter" do
      doc = SolrDocument.find('jg267fg4283')
      expect { doc.bogus_field="dude" }.to raise_error
    end
    
    it "should update the value of a single valued field" do
      new_value="cool new title"
      doc = SolrDocument.find('jg267fg4283')
      expect(doc['title_tsi']).to be_nil
      doc.title=new_value
      doc['title_tsi']=new_value # solr field was updated
      expect(doc.title).to eq(new_value)
    end

    it "should update the value of a multivalued field directly" do
      new_value=['Jaguar','Porsche']
      doc = SolrDocument.find('yh093pt9555')
      expect(doc.marque).not_to eq(new_value)
      doc.marque=new_value
      doc['marque_ssim']=new_value # solr field was updated
      expect(doc.marque).to eq(new_value)
    end 

    it "should update the value of a multivalued field via the special MVF syntax, leave extra spaces" do
      new_value=' Jaguar |  Porsche'
      new_value_as_array=[' Jaguar ','  Porsche']
      doc = SolrDocument.find('yh093pt9555')
      expect(doc.marque).not_to eq(new_value_as_array)
      expect(doc.marque_mvf).not_to eq(new_value)
      doc.marque_mvf=new_value
      doc['marque_ssim']=new_value_as_array # solr field was updated
      expect(doc.marque).to eq(new_value_as_array)
      expect(doc.marque.class).to eq(Array)
      expect(doc.marque_mvf).to eq(new_value_as_array.join(' | '))
      expect(doc.marque_mvf.class).to eq(String)
    end
           
  end
  
  describe "saving" do
   
    before :each do
      @druid='yt907db4998'
      reindex_solr_docs(@druid)
      @doc = SolrDocument.find(@druid)
      cleanup_editstore_changes
    end
    
    after :each do
      reindex_solr_docs(@druid)
      cleanup_editstore_changes # transactions don't seem to work with the second editstore database, so cleanup
    end    
    
    it "should save an update to a single value field, and propogate to solr and editstore databases" do
      
      expect(Editstore::Change.count).to eq(0)
    
      new_value='Test changed it' 
      old_value=@doc.title
      expect(@doc.title).not_to eq(new_value) # update the title
      @doc.title=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.title).to eq(new_value)
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      expect(editstore_entry(Editstore::Change.last,:field=>'title_tsi',:new_value=>new_value,:old_value=>old_value,:druid=>@druid,:operation=>'update',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(1)
      
    end

    it "should save an update to a single value field, and propogage to solr but not to editstore database if not configured to do that" do
      
      # the priority field is configured to not propogate to editstore
      
      expect(Editstore::Change.count).to eq(0)
    
      new_value='2' 
      old_value=@doc.priority
      expect(@doc.priority).not_to eq(new_value)
      @doc.priority=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.priority).to eq(new_value.to_i)
      
       # confirm we don't have a new change in the database
      expect(Editstore::Change.count).to eq(0)
      
    end

    it "should save an update to a single value field with special odd characters, and propogage to solr and editstore databases" do
      
      expect(Editstore::Change.count).to eq(0)
    
      new_value="Test changed it, including apostraphe ' and slahses \\  /  and a quote \" and a pipe |  this not a multivalued field, should be fine " 
      old_value=@doc.title
      expect(@doc.title).not_to eq(new_value) # update the title
      @doc.title=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.title).to eq(new_value.strip)
      
       # confirm we have a new change in the database
      expect(editstore_entry(Editstore::Change.last,:field=>'title_tsi',:new_value=>new_value.strip,:old_value=>old_value,:druid=>@druid,:operation=>'update',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(1)

    end
    
    it "should save a new entry to a single value field, and propogage to solr and editstore databases" do
      
      expect(Editstore::Change.count).to eq(0)
    
      new_value='Patrick Starfish' 
      expect(@doc.photographer).to eq("")
      @doc.photographer=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.photographer).to eq(new_value)
      
       # confirm we have a new change in the database
      expect(editstore_entry(Editstore::Change.last,:field=>'photographer_ssi',:new_value=>new_value,:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(1)
      
    end

    it "should clear out an existing entry to a single value field, and propogage to solr and editstore databases" do
      
      expect(Editstore::Change.count).to eq(0)
    
      expect(@doc.entrant).to eq(["Fastguy, Some"])
      @doc.entrant=""
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.entrant).to eq("")
      
       # confirm we have a new change in the database
      expect(editstore_entry(Editstore::Change.last,:field=>'entrant_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(1)
      
    end

    it "should clear out an existing entry to a mutlivalued field, and propogage to solr and editstore databases" do
      
      expect(Editstore::Change.count).to eq(0)
    
      # current value
      expect(@doc.vehicle_model).to eq(['Mystique','328i','GT-350'])

      # clear out values
      @doc.vehicle_model_mvf=''
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.vehicle_model).to eq("")
      
       # confirm we have a new change in the database
      expect(editstore_entry(Editstore::Change.last,:field=>'model_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(1)
      
    end
    
    it "should save a new entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      expect(Editstore::Change.count).to eq(0)
      new_values=' Ferrari |  Tesla '  
      new_values_as_array=['Ferrari','Tesla']
      
      # currently blank
      expect(@doc.marque).to eq("")
      
      # set new values
      @doc.marque_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.marque).to eq(new_values_as_array)
      expect(reload_doc.marque_mvf).to eq(new_values_as_array.join(' | '))
      
       # confirm we have new changes in the database
      last_edits=Editstore::Change.all
      expect(editstore_entry(last_edits[0],:field=>'marque_ssim',:new_value=>new_values_as_array[0],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready)).to be_truthy
      expect(editstore_entry(last_edits[1],:field=>'marque_ssim',:new_value=>new_values_as_array[1],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready)).to be_truthy 
      expect(Editstore::Change.count).to eq(2)
      
    end

    it "shouldn't add anything to the Editstore database if nothing is changed, even is save is called" do
      
      expect(Editstore::Change.count).to eq(0)
      saved=@doc.save
      expect(saved).to be_truthy
      expect(Editstore::Change.count).to eq(0)
      
    end

    it "shouldn't add anything to the Editstore database when some fields do not actually change, even is save is called" do
      
      expect(Editstore::Change.count).to eq(0)
      @doc.title = @doc[:title_tsi]
      @doc.years_mvf = @doc[:pub_year_isim].join(" | ")
      saved=@doc.save
      expect(saved).to be_truthy
      expect(Editstore::Change.count).to eq(0)
      
    end

    it "shouldn't add anything to the Editstore database or update solr and save nothing when there is an invalid value" do
      
      expect(Editstore::Change.count).to eq(0)
      expect(@doc.full_date).to eq('')
      @doc.full_date='bogusness'
      expect(@doc.valid?).to be_falsey
      saved=@doc.save
      expect(saved).to be_falsey
      reload_doc=SolrDocument.find(@druid)
      expect(reload_doc.full_date).to eq('')
      expect(Editstore::Change.count).to eq(0)
      
    end
    
    it "should save an updated entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      expect(Editstore::Change.count).to eq(0)
      new_values=' Contour |128i '  
      new_values_as_array=['Contour','128i']
      
      # current values
      expect(@doc.vehicle_model).to eq(['Mystique','328i','GT-350'])

      # set new value
      @doc.vehicle_model_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      expect(reload_doc.vehicle_model).to eq(new_values_as_array)
      expect(reload_doc.vehicle_model_mvf).to eq(new_values_as_array.join(' | '))
      
       # confirm we have new changes in the database, which includes a delete and two adds
      last_edits=Editstore::Change.all
      expect(editstore_entry(last_edits[0],:field=>'model_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready)).to be_truthy
      expect(editstore_entry(last_edits[1],:field=>'model_ssim',:new_value=>new_values_as_array[0],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready)).to be_truthy
      expect(editstore_entry(last_edits[2],:field=>'model_ssim',:new_value=>new_values_as_array[1],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready)).to be_truthy
      expect(Editstore::Change.count).to eq(3)
      
    end

  end
  
  describe "cached edits" do
  
    before :each do
      @doc = SolrDocument.find('yt907db4998')
      cleanup_editstore_changes
    end
    
    after :each do
      cleanup_editstore_changes
    end
    
    it "should not have any unsaved edits when initialized" do
      expect(unchanged(@doc)).to be_truthy
    end

    it "should indicate when a change has occurred to a field, but not saved" do
      expect(Editstore::Change.count).to eq(0)
      new_value="new title!"
      old_value=@doc.title
      expect(unchanged(@doc)).to be_truthy
      @doc.title=new_value
      expect(changed(@doc,{:title_tsi=>new_value})).to be_truthy
      expect(@doc.title).to eq(new_value) # change is in memory
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      expect(reload_doc.title).to eq(old_value) 
      expect(Editstore::Change.count).to eq(0)
    end

    it "should not cache an edit when a single valued field is set but hasn't actually changed" do
      expect(Editstore::Change.count).to eq(0)
      old_value=@doc.title
      expect(unchanged(@doc)).to be_truthy
      @doc.title=old_value
      expect(unchanged(@doc)).to be_truthy      
      expect(Editstore::Change.count).to eq(0)
    end

    it "should not cache an edit when a mutivalued field with one value is set but hasn't actually changed" do
      expect(Editstore::Change.count).to eq(0)
      expect(@doc.years).to eq([1960]) # its an array with an integer value
      expect(unchanged(@doc)).to be_truthy
      @doc.years="1960" # set to a single valued string, but it should be equivalent and not marked as a change
      expect(unchanged(@doc)).to be_truthy
      @doc.years_mvf="1960" # now set the equivalent _mvf field, but it should be equivalent and not marked as a change
      expect(unchanged(@doc)).to be_truthy    
      expect(Editstore::Change.count).to eq(0)
    end

    it "should not cache an edit when a mutivalued field with two values is set but hasn't actually changed" do
      doc2=SolrDocument.find('yh093pt9555')
      expect(Editstore::Change.count).to eq(0)
      expect(doc2.years).to eq([1955,1956]) # its an array with integer value2
      expect(unchanged(doc2)).to be_truthy
      doc2.years=[1955,1956] # set to an equivalent array
      expect(unchanged(doc2)).to be_truthy
      doc2.years=["1955","1956"] # set to an equivalent array but of string
      expect(unchanged(doc2)).to be_truthy
      doc2.years_mvf="1955 | 1956" # now set the equivalent _mvf field like it would be coming from the form
      expect(unchanged(doc2)).to be_truthy
      expect(Editstore::Change.count).to eq(0)
    end
    
    it "should cache an edit when a mutivalued field is set and has changed" do
      expect(Editstore::Change.count).to eq(0)
      old_value=[1960]
      expect(@doc.years).to eq(old_value) # its an array with an integer value
      expect(unchanged(@doc)).to be_truthy
      @doc.years="1961"
      expect(changed(@doc,{:pub_year_isim=>['1961']})).to be_truthy
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      expect(reload_doc.years).to eq(old_value)    
      expect(Editstore::Change.count).to eq(0)  # no changes to Editstore yet
    end

    it "should cache an edit when a mutivalued field is set using the special MVF syntax and has changed" do
      expect(Editstore::Change.count).to eq(0)
      old_value=[1960]
      expect(@doc.years).to eq(old_value) # its an array with an integer value
      expect(unchanged(@doc)).to be_truthy
      @doc.years_mvf="1961|1962"
      @doc.years=['1961','1962'] # should return as an array
      expect(changed(@doc,{:pub_year_isim=>['1961','1962']})).to be_truthy
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      expect(reload_doc.years).to eq(old_value)    
      expect(Editstore::Change.count).to eq(0)  # no changes to Editstore yet
    end

  end
  
end
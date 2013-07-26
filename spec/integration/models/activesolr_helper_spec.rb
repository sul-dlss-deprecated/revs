require "spec_helper"

describe ActivesolrHelper, :integration => true do
  
  describe "class level methods" do 
     
    it "find method should return an instance of a solr document that is an item" do
      doc = SolrDocument.find('yt907db4998')
      doc.should be_a SolrDocument
      doc.title.should == 'Record 1'
      doc.is_item?.should be_true
    end
  
    it "should have the correct mvf field marker" do
      SolrDocument.multivalued_field_marker.should == '_mvf'
    end
  
    it "should indicate when values are equivalent, whether arrays of regardless of type or extra leading/trailing spaces" do
      SolrDocument.is_equal?(1,"1").should be_true
      SolrDocument.is_equal?("1","1").should be_true
      SolrDocument.is_equal?(["1"],"1").should be_true
      SolrDocument.is_equal?(["1"],1).should be_true
      SolrDocument.is_equal?(["abc"],"abc").should be_true
      SolrDocument.is_equal?("abc",["abc"]).should be_true
      SolrDocument.is_equal?("abc",["abc","123"]).should be_false
      SolrDocument.is_equal?([123,"abc"],["abc","123"]).should be_true
      SolrDocument.is_equal?([123,"  abc"],["abc","123 "]).should be_true
    end
    
    it "to_array should convert strings to arrays, and leave arrays alone" do
      SolrDocument.to_array('test').should == ['test']
      SolrDocument.to_array(1).should == [1]
      SolrDocument.to_array('').should == ['']
      SolrDocument.to_array(nil).should == [nil]
      SolrDocument.to_array([]).should == []
      SolrDocument.to_array(['test']).should == ['test']
      SolrDocument.to_array(['test','test2']).should == ['test','test2']
    end
  
    it "should return if a value is blank, either an array of blank entries or a single blank value" do
      SolrDocument.blank_value?(nil).should be_true
      SolrDocument.blank_value?([nil]).should be_true
      SolrDocument.blank_value?(['']).should be_true
      SolrDocument.blank_value?(['','']).should be_true
      SolrDocument.blank_value?('a').should be_false
      SolrDocument.blank_value?(['a']).should be_false    
      SolrDocument.blank_value?(['a','']).should be_false    
      SolrDocument.blank_value?(['a',nil]).should be_false    
    end
  
  end

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

    it "should retrieve a couple multivalued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should == doc['marque_ssim']
      doc.marque.class.should == Array
      doc.people.should == doc['people_ssim']
      doc.people.class.should == Array
    end

    it "should retrieve a couple a multivalued fields correctly with a split when using the MFV syntax" do
      doc = SolrDocument.find('yh093pt9555')
      doc.marque_mvf.should == doc['marque_ssim'].join(' | ')
      doc.marque_mvf.class.should == String
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
  
  describe "setter methods" do
    
    it "should update the value of a single valued field" do
      new_value="cool new title"
      doc = SolrDocument.find('jg267fg4283')
      doc['title_tsi'].should be_nil
      doc.title=new_value
      doc['title_tsi']=new_value # solr field was updated
      doc.title.should == new_value
    end

    it "should update the value of a multivalued field directly" do
      new_value=['Jaguar','Porsche']
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should_not == new_value
      doc.marque=new_value
      doc['marque_ssim']=new_value # solr field was updated
      doc.marque.should == new_value
    end 

    it "should update the value of a multivalued field via the special MVF syntax, leave extra spaces" do
      new_value=' Jaguar |  Porsche'
      new_value_as_array=[' Jaguar ','  Porsche']
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should_not == new_value_as_array
      doc.marque_mvf.should_not == new_value
      doc.marque_mvf=new_value
      doc['marque_ssim']=new_value_as_array # solr field was updated
      doc.marque.should == new_value_as_array
      doc.marque.class.should == Array
      doc.marque_mvf.should == new_value_as_array.join(' | ')
      doc.marque_mvf.class.should == String
    end
           
  end
  
  describe "saving" do

    before :each do
      @druid='yt907db4998'
      @doc = SolrDocument.find(@druid)
    end
    
    after :each do
      reindex_solr_docs(@druid)
    end    
    
    it "should save an update to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      new_value='Test changed it' 
      old_value=@doc.title
      @doc.title.should_not == new_value # update the title
      @doc.title=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.title.should == new_value
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      last_edit.field.should == 'title_tsi'
      last_edit.new_value.should == new_value
      last_edit.old_value.should == old_value
      last_edit.druid.should == @druid
      last_edit.operation.should == 'update'
      last_edit.state.should == Editstore::State.ready
      Editstore::Change.count.should == 1
      
    end

    it "should save a new entry to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      new_value='Patrick Starfish' 
      @doc.photographer.should == ""
      @doc.photographer=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.photographer.should == new_value
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      last_edit.field.should == 'photographer_ssi'
      last_edit.new_value.should == new_value
      last_edit.old_value.should be_nil
      last_edit.druid.should == @druid
      last_edit.operation.should == 'create'
      last_edit.state.should == Editstore::State.ready
      Editstore::Change.count.should == 1
      
    end

    it "should clear out an existing entry to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      @doc.entrant.should == "Fastguy, Some"
      @doc.entrant=""
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.entrant.should == ""
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      last_edit.field.should == 'entrant_ssi'
      last_edit.new_value.should == ''
      last_edit.old_value.should be_nil
      last_edit.druid.should == @druid
      last_edit.operation.should == 'delete'
      last_edit.state.should == Editstore::State.ready
      Editstore::Change.count.should == 1
      
    end

    it "should clear out an existing entry to a mutlivalued field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      # current value
      @doc.vehicle_model.should == ['Mystique','328i']

      # clear out values
      @doc.vehicle_model_mvf=''
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.vehicle_model.should == ""
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      last_edit.field.should == 'model_ssim'
      last_edit.new_value.should == ''
      last_edit.old_value.should be_nil
      last_edit.druid.should == @druid
      last_edit.operation.should == 'delete'
      last_edit.state.should == Editstore::State.ready
      Editstore::Change.count.should == 1
      
    end
    
    it "should save a new entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      Editstore::Change.count.should == 0
      new_values=' Ferrari |  Tesla '  
      new_values_as_array=['Ferrari','Tesla']
      
      # currently blank
      @doc.marque.should == ""
      
      # set new values
      @doc.marque_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.marque.should == new_values_as_array
      reload_doc.marque_mvf.should == new_values_as_array.join(' | ')
      
       # confirm we have new changes in the database
      last_edits=Editstore::Change.all
      last_edits[0].field.should == 'marque_ssim'
      last_edits[0].new_value.should == new_values_as_array[0]
      last_edits[0].old_value.should be_nil
      last_edits[0].druid.should == @druid
      last_edits[0].operation.should == 'create'
      last_edits[0].state.should == Editstore::State.ready
      
      last_edits[1].field.should == 'marque_ssim'
      last_edits[1].new_value.should == new_values_as_array[1]
      last_edits[1].old_value.should be_nil
      last_edits[1].druid.should == @druid
      last_edits[1].operation.should == 'create'
      last_edits[1].state.should == Editstore::State.ready      
      Editstore::Change.count.should == 2
      
    end

    it "shouldn't add anything to the Editstore database if nothing is changed, even is save is called" do
      
      Editstore::Change.count.should == 0
      saved=@doc.save
      saved.should be_true
      Editstore::Change.count.should == 0
      
    end

    it "shouldn't add anything to the Editstore database or update solr and save nothing when there is an invalid value" do
      
      Editstore::Change.count.should == 0
      @doc.full_date.should == ''
      @doc.full_date='bogusness'
      @doc.valid?.should be_false
      saved=@doc.save
      saved.should be_false
      reload_doc=SolrDocument.find(@druid)
      reload_doc.full_date.should == ''
      Editstore::Change.count.should == 0
      
    end
    
    it "should save an updated entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      Editstore::Change.count.should == 0
      new_values=' Contour |128i '  
      new_values_as_array=['Contour','128i']
      
      # current values
      @doc.vehicle_model.should == ['Mystique','328i']

      # set new value
      @doc.vehicle_model_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.vehicle_model.should == new_values_as_array
      reload_doc.vehicle_model_mvf.should == new_values_as_array.join(' | ')
      
       # confirm we have new changes in the database, which includes a delete and two adds
      last_edits=Editstore::Change.all
      last_edits[0].field.should == 'model_ssim'
      last_edits[0].new_value.should be == ''
      last_edits[0].old_value.should be_nil
      last_edits[0].druid.should == @druid
      last_edits[0].operation.should == 'delete'
      last_edits[0].state.should == Editstore::State.ready
      
      last_edits[1].field.should == 'model_ssim'
      last_edits[1].new_value.should == new_values_as_array[0]
      last_edits[1].old_value.should be_nil
      last_edits[1].druid.should == @druid
      last_edits[1].operation.should == 'create'
      last_edits[1].state.should == Editstore::State.ready
      
      last_edits[2].field.should == 'model_ssim'
      last_edits[2].new_value.should == new_values_as_array[1]
      last_edits[2].old_value.should be_nil
      last_edits[2].druid.should == @druid
      last_edits[2].operation.should == 'create'
      last_edits[2].state.should == Editstore::State.ready      
      Editstore::Change.count.should == 3
      
    end

  end
  
  describe "cached edits" do
  
    before :each do
      @doc = SolrDocument.find('yt907db4998')
    end
    
    it "should not have any unsaved edits when initialized" do
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.valid?.should be_true
    end

    it "should indicate when a change has occurred to a field, but not saved" do
      Editstore::Change.count.should == 0
      new_value="new title!"
      old_value=@doc.title
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.title=new_value
      @doc.dirty?.should be_true
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {:title_tsi=>new_value}
      @doc.title.should == new_value # change is in memory
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.title.should == old_value 
      Editstore::Change.count.should == 0
    end

    it "should not cache an edit when a single valued field is set but hasn't actually changed" do
      Editstore::Change.count.should == 0
      old_value=@doc.title
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.title=old_value
      @doc.dirty?.should be_false
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {}
      Editstore::Change.count.should == 0
    end

    it "should not cache an edit when a mutivalued field is set but hasn't actually changed" do
      Editstore::Change.count.should == 0
      @doc.years.should == [1960] # its an array with an integer value
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.years="1960" # set to a single valued string, but it should be equivalent and not marked as a change
      @doc.dirty?.should be_false
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {}
      @doc.years_mvf="1960" # now set the equivalent _mvf field, but it should be equivalent and not marked as a change
      @doc.dirty?.should be_false
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {}      
      Editstore::Change.count.should == 0
    end

    it "should cache an edit when a mutivalued field is set and has changed" do
      Editstore::Change.count.should == 0
      old_value=[1960]
      @doc.years.should == old_value # its an array with an integer value
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.years="1961"
      @doc.dirty?.should be_true
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {:pub_year_isim=>'1961'}  
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should == old_value    
      Editstore::Change.count.should == 0  # no changes to Editstore yet
    end

    it "should cache an edit when a mutivalued field is set using the special MVF syntax and has changed" do
      Editstore::Change.count.should == 0
      old_value=[1960]
      @doc.years.should == old_value # its an array with an integer value
      @doc.dirty?.should be_false
      @doc.unsaved_edits.should == {}
      @doc.years_mvf="1961|1962"
      @doc.years=['1961','1962'] # should return as an array
      @doc.dirty?.should be_true
      @doc.valid?.should be_true
      @doc.unsaved_edits.should == {:pub_year_isim=>['1961','1962']}  
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should == old_value    
      Editstore::Change.count.should == 0  # no changes to Editstore yet
    end

  end
  
end
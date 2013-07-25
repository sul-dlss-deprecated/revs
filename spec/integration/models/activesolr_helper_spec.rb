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
      SolrDocument.multivalued_field_marker.should be == '_mvf'
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
      SolrDocument.to_array('test').should be == ['test']
      SolrDocument.to_array(1).should be == [1]
      SolrDocument.to_array('').should be == ['']
      SolrDocument.to_array(nil).should be == [nil]
      SolrDocument.to_array([]).should be == []
      SolrDocument.to_array(['test']).should be == ['test']
      SolrDocument.to_array(['test','test2']).should be == ['test','test2']
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
  
  describe "cached edits and validation" do
  
    it "should not have any unsaved edits when initialized" do
      doc = SolrDocument.find('yt907db4998')
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.valid?.should be_true
    end

    it "should indicate when a chance has occurred to a field, but not saved" do
      Editstore::Change.count.should be == 0
      new_value="new title!"
      doc = SolrDocument.find('yt907db4998')
      old_value=doc.title
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.title=new_value
      doc.dirty?.should be_true
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {:title_tsi=>new_value}
      doc.title.should be == new_value # change is in memory
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.title.should be == old_value 
      Editstore::Change.count.should be == 0
    end

    it "should not cache an edit when a single valued field is set but hasn't actually changed" do
      Editstore::Change.count.should be == 0
      doc = SolrDocument.find('yt907db4998')
      old_value=doc.title
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.title=old_value
      doc.dirty?.should be_false
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {}
      Editstore::Change.count.should be == 0
    end

    it "should not cache an edit when a mutivalued field is set but hasn't actually changed" do
      Editstore::Change.count.should be == 0
      doc = SolrDocument.find('yt907db4998')
      doc.years.should be == [1960] # its an array with an integer value
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.years="1960" # set to a single valued string, but it should be equivalent and not marked as a change
      doc.dirty?.should be_false
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {}
      doc.years_mvf="1960" # now set the equivalent _mvf field, but it should be equivalent and not marked as a change
      doc.dirty?.should be_false
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {}      
      Editstore::Change.count.should be == 0
    end

    it "should cache an edit when a mutivalued field is set and has changed" do
      Editstore::Change.count.should be == 0
      doc = SolrDocument.find('yt907db4998')
      old_value=[1960]
      doc.years.should be == old_value # its an array with an integer value
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.years="1961"
      doc.dirty?.should be_true
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {:pub_year_isim=>'1961'}  
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should be == old_value    
      Editstore::Change.count.should be == 0  # no changes to Editstore yet
    end

    it "should cache an edit when a mutivalued field is set using the special MVF field and has changed" do
      Editstore::Change.count.should be == 0
      doc = SolrDocument.find('yt907db4998')
      old_value=[1960]
      doc.years.should be == old_value # its an array with an integer value
      doc.dirty?.should be_false
      doc.unsaved_edits.should be == {}
      doc.years_mvf="1961|1962"
      doc.dirty?.should be_true
      doc.valid?.should be_true
      doc.unsaved_edits.should be == {:pub_year_isim=>['1961','1962']}  
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should be == old_value    
      Editstore::Change.count.should be == 0  # no changes to Editstore yet
    end

    it "should catch invalid dates" do
      doc = SolrDocument.find('yt907db4998')
      doc.valid?.should be_true
      doc.full_date = 'crap' # bad value
      doc.dirty?.should be_true
      doc.valid?.should be_false
      doc.save.should be_false      
      doc.full_date = '5/1/2001' # this is ok
      doc.valid?.should be_true
   end

    it "should catch invalid years" do
      doc = SolrDocument.find('yt907db4998')
      doc.valid?.should be_true
      doc.years = ['crap','1961'] # bad value
      doc.dirty?.should be_true
      doc.valid?.should be_false
      doc.save.should be_false      
      doc.years = 'crap' # this is bad
      doc.valid?.should be_false
      doc.years = '1999' # this is ok
      doc.valid?.should be_true
      doc.years = ['1959','1961'] # ok
      doc.valid?.should be_true      
      doc.years_mvf = '1959|1961' # mvf ok
      doc.valid?.should be_true
      doc.years_mvf = 'abc|1961' # bad
      doc.valid?.should be_false
      doc.years_mvf = '1961' # ok
      doc.valid?.should be_true
   end
      
  end
  
end
class Item

  # A nify little helper class to grab you a SolrDocument model given an ID.  Helpful on the console:
  # doc = Item.find('qb957rw1430')
  # puts doc.title

  def self.find(id)
    response = Blacklight.solr.select(
                                :params => {
                                  :fq => "id:\"#{id}\"" }
                              )
    docs=response["response"]["docs"].map{|d| SolrDocument.new(d) }
    docs.size == 0 ? nil : docs.first
  end
  
  def self.bulk_update(selected_druids,field_name,new_value)
    
    new_values=new_value.split("|") # pipes can be used to denote multiple values in a multivalued field 
    
    selected_druids.each do |druid|
      
      item=self.find(druid)
      old_values=item[field_name]
      
      if !old_values.nil? && old_values.class != Array  # the previous field exist and is not mutivalued, so this is a change operation on a single field
        Editstore::Change.create(:new_value=>new_values.first,:old_value=>old_values,:operation=>:update,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)
      end
      if !old_values.nil? && old_values.class == Array # the previous field exists and is multivalued, so lets delete all the old values, so we can create the new ones (this is because bulk does not pinpoint change values, it simply does a full replace of any multivalued field)    
        old_values.each {|old_value| Editstore::Change.create(:old_value=>old_value,:operation=>:delete,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)}
      end
      if old_values.nil? || (!old_values.nil? && old_values.class == Array) # if previous value didn't exist or we are updating a multvalued field, let's create the new values
        new_values.each {|new_value| Editstore::Change.create(:new_value=>new_value,:operation=>:create,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)} # add all new values to DOR        
      end
      
      item.set_field(field_name,new_values) # update solr
      
    end
    
  end
  
  # used to build the drop down menu of available fields for bulk updating -- add the text to be shown to user and the field in solr doc and Editstore fields table
  def self.bulk_update_fields
    [
      ['Title','title_tsi'],
      ['Format','format_ssim'],
      ['Year','pub_year_isim'],
      ['Description','description_tsim'],
      ['Marque','marque_ssim'],
      ['Model','model_ssim'],
      ['Model Year','model_year_ssim'],
      ['People','people_ssim'],
      ['Entrant','entrant_ssi'],
      ['Current Owner','current_owner_ssi'],
      ['Venue','venue_ssi'],
      ['Track','track_ssi'],
      ['Event','event_ssi'],
      ['Location','location_ssi'],
      ['Group/Class','group_class_tsi'],
      ['Race Data','race_data_tsi'],
      ['Photographer','photographer_ssi']
    ]
  end
    
end

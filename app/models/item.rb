class Item

  # A nify little helper class to grab you a SolrDocument model given an ID.  Helpful on the console:
  # doc = Item.find('qb957rw1430')
  # puts doc.title

  extend DateHelpers

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
    
    # perform some validation of fields
    case field_name.to_sym
      when :pub_date_ssi
        valid = new_values.all? {|new_value| get_full_date(new_value)}
      when :pub_year_isim,:pub_year_single_isi
        valid = new_values.all? {|new_value| is_valid_year?(new_value)}
      else
        valid=true
    end
    
    if valid # entered values were valid
    
      selected_druids.each do |druid|
      
        item=self.find(druid)
        old_values=item[field_name]
      
        if !old_values.nil? # if a previous value(s) exist for this field, we either need to do an update (single valued), or delete all existing values (multivalued)
          if old_values.class == Array  # multivalued; delete all old values (this is because bulk does not pinpoint change values, it simply does a full replace of any multivalued field)    
            Editstore::Change.create(:operation=>:delete,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid,:client_note=>'delete all old values in multivalued field')
          else # single-valued, change operation 
            Editstore::Change.create(:new_value=>new_values.first.strip,:old_value=>old_values.strip,:operation=>:update,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)
          end
        end
      
        if old_values.nil? || old_values.class == Array # if previous value didn't exist or we are updating a multvalued field, let's create the new values
          new_values.each {|new_value| Editstore::Change.create(:new_value=>new_value.strip,:operation=>:create,:state_id=>Editstore::State.ready.id,:field=>field_name,:druid=>druid)} # add all new values to DOR        
        end
      
        item.set_field(field_name,new_values) # update solr
      
      end

      return true
      
    else # something was invalid
      
      return false
    
    end
    
  end
  
  # used to build the drop down menu of available fields for bulk updating -- add the text to be shown to user and the field in solr doc and Editstore fields table
  def self.bulk_update_fields
    [
      ['Title','title_tsi'],
      ['Format','format_ssim'],
      ['Years','pub_year_isim'],
      ['Date','pub_date_ssi'],
      ['Description','description_tsim'],
      ['Marques','marque_ssim'],
      ['Models','model_ssim'],
      ['Model Years','model_year_ssim'],
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

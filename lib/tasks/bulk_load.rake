require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'
require 'csv'

desc "Load all changes to the metadata from CSV files located in TBD"
task :bulk_load do
  change_file_location = "/tmp"
  change_file_extension = ".csv"
  ignore_fields = ['sourceid', 'filename', 'year']  
  csv_to_solr = {'label' => 'title',
    'description' => SolrDocument.field_mappings[:description][:field],
    'photographer' => SolrDocument.field_mappings[:photographer][:field],
    
    
, 'collection_name'=>'collection_ssim', 'label'=>'title_tsi', 'year'=>''}
  
  
  
  
  :years=>{:field=>'pub_year_isim'},
  :full_date=>{:field=>'pub_date_ssi'},
  
  :people=>{:field=>'people_ssim'},
  :subjects=>{:field=>'subjects_ssim'},
  :city_section=>{:field=>'city_sections_ssi'},
  :city=>{:field=>'cities_ssi'},
  :state=>{:field=>'states_ssi'},
  :country=>{:field=>'countries_ssi'},
  :formats=>{:field=>'format_ssim'},
  :identifier=>{:field=>'source_id_ssi'},
  :production_notes=>{:field=>'prod_notes_tsi'},
  :institutional_notes=>{:field=>'inst_notes_tsi'},
  :metadata_sources=>{:field=>'metadata_sources_tsi'},
  :has_more_metadata=>{:field=>'has_more_metadata_ssi'},
  :vehicle_markings=>{:field=>'vehicle_markings_tsi'},
  :marque=>{:field=>'marque_ssim'},
  :vehicle_model=>{:field=>'model_ssim'},
  :model_year=>{:field=>'model_year_ssim'},
  :current_owner=>{:field=>'current_owner_ssi'},
  :entrant=>{:field=>'entrant_ssi'},
  :venue=>{:field=>'venue_ssi'},
  :track=>{:field=>'track_ssi'},
  :event=>{:field=>'event_ssi'},
  :group_class=>{:field=>'group_class_tsi'},
  :race_data=>{:field=>'race_data_tsi'},
  :priority=>{:field=>'priority_isi',:default=>0,:editstore=>false},
  :collections=>{:field=>'is_member_of_ssim'},
  :collection_names=>{:field=>'collection_ssim'},
  :highlighted=>{:field=>'highlighted_ssi'},
  }  
  
  
  #Get a list of all the files we need to process and loop over them
  change_files = Dir.glob(File.join(change_file_location, change_file_extension))
  change_files.each do |file|
  source_id_posistion = 1 
  
  
    edits = {}
    CSV.foreach(file, :headers=> true, :header_converter => :symbol, :converters => :all) do |row|
      edits[row.fields[source_id_posistion]] = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
    end
  
    edits.each do |key, value|
      doc = SolrDocument.new(Blacklight.solr.select(:params =>{:q=>'source_id_ssi:"'+key+'"'})["response"]["docs"][0])
      value.except(ignore_fields).keys.each do |field|
       
      
          doc.send(csv_to_solr[key]) = value[key]
          
          
      end
      
      if value.keys.include('year')
        #Figure out which date field to use here
      end
      
      doc.save
      #TODO: Logging for a false save
      
    end  
  
 
  
  end
  
  
  
end
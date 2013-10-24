require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'
require 'csv'
require 'countries'
require 'pathname'

namespace :revs do
  @sourceid = 'sourceid'
  @seperator = '|'
  @filename = 'filename'
  @csv_extension_wild = '*.csv'
  @csv_extension = ".csv"
  @log_extension = ".out" #use something beside .log to avoid the autorotate feature for .log files
  @success = "SUCCESS:"
  @failure = "FAILURE:"
  
  desc "When passed the location of .csv file(s) and a list of headers, this will generate csv with just those fields, plus fields to find the solr document"
  #Run me: rake revs:bulk_load["SHEETS_LOCATION", header1|header2|etc, output_name] RAILS_ENV=production
  task :csv_for_fields, [:csv_files, :fields, :fn] => :environment do |t, args|
    always_present = [@sourceid, @filename]
    additional_headers = args[:fields].split(@seperator) 
    all_fields = always_present + additional_headers
    files = load_csv_files_from_directory(args[:csv_files])
    full_output_path = "#{Rails.root}/lib/assets/#{args[:fn]}#{@csv_extension}"
    
    #Start Logging
    log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.csv_for_fields#{@log_extension}")
    log.level = Logger::INFO
    log.info("Starting run with the command line args of csv_fields: #{args[:csv_files]} fields: #{args[:fields]} output filename: #{args[:fn]}")
    
    #Setup the output csv
      CSV.open(full_output_path, "wb") do |csv|
        #Write Out The Headers
        csv << all_fields
        
        #Load each sheet we are taking data from
          files.each do |file|
             data = read_csv_with_headers(file)
             #Make sure the always there files are present
               always_present.each do |header|
                 log.warn("File #{file} lacks required header: #{header}") if data.headers().include?(header) == false
               end
               data.each do |row|
                 out_array = []
                   all_fields.each do |field|
                     out_array.append(row[field])
                     log.warn("Nil value for #{field}, a required field, in #{file}") if row[field] == nil and always_present.include?(field)  
                   end
                 csv << out_array   
               end
      
          end
       end  
  end

  
  
  desc "Load all changes to the metadata from CSV files located in TBD"
  #Run me: rake revs:bulk_load["SHEETS_LOCATION"] RAILS_ENV=production
  task :bulk_load, [:change_files_loc, :local_testing] => :environment do |t, args|
    local_testing = args[:local_testing] || false #Assume we are not testing locally unless told so
    debug_source_id = '2012-027NADI-1967-b1_1.0_0008'
    
    marque_file = File.open('lib/assets/revs-lc-marque-terms.obj','rb'){|io| Marshal.load(io)}
    change_file_location = args[:change_files_loc]
    change_file_extension = @csv_extension_wild
    sourceid = @sourceid
    location = "location"
    format = "format"
    marque = "marque"
    filename = @filename
    year = "date"
    full_date = "full_date"
    seperator =  @seperator
    assigner = "="
    multi = "_mvf"
    model = 'model'
    model_year = 'model_year'
    ignore_fields = [sourceid, location, marque, filename]  
    location_fields = ['country', 'city', 'state']
    additional_fields = location_fields + [full_date]#add other arrays here if we do anymore splitting
    comma = ","
    comma_splits = [marque, model]
    file_ext = ".tif"
   
  
    #Map the csv names to the field names from 
    csv_to_solr = {'label' => 'title',   
                   model  => 'vehicle_model',
                   year => 'years',
                   format => 'formats',
                   'collection_name' => 'collection_names',
                   'inst_notes' => 'institutional_notes',
                   'prod_notes' => 'production_notes'
                  }
    solr_keys = [ 'title', 'description', 'photographer', 'years', 'full_date', 'people', 'subjects', 'city_section',
                  'city', 'state', 'country', 'formats', 'identifier', 'production_notes', 'institutional_notes',
                  'metadata_sources', 'has_more_metadata', 'vehicle_markings', 'marque', 'vehicle_model', 'model_year',
                  'current_owner', 'entrant', 'venue', 'track', 'event', 'group_class', 'race_data', 'priority', 'collections',
                  'collection_names', 'highlighted']
   
   #These should be the field name from /app/models/solr_document.rb
   multi_values = ['vehicle_model', 'years', "formats", "model_year", "marque", "people"]
  
   #All the CSV headers we know how to handle
   known_headers = csv_to_solr.keys + ignore_fields + solr_keys
    
   #Get a list of all the files we need to process and loop over them
   change_files = load_csv_files_from_directory(change_file_location)
  
   #Setup a master log
   master_log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.revs_bulk_load#{@log_extension}")
   sleep 1 #This way the log timestamp will be at least oen second ahead of the next log we make and the master log ends up at the top of the list
     
    #Process Each File 
    change_files.each do |file| 
      error_count = 0
      name = Pathname.new(file).basename.to_s
      name.slice! @csv_extension
      log = Logger.new("#{Rails.root}/log/#{Time.now.to_i}.#{name}#{@log_extension}")
      master_log.info("#{file} started at #{Time.now}")
      
      log.level = Logger::ERROR
      
      #Load in the CSV, with the top row being taken as the header
      #changes = CSV.parse(File.read(file), :headers => true )
      changes = read_csv_with_headers(file)
      
      #Ensure we can handle all headers we've found
      bad_header = false 
      changes.headers().each do |header|
        if not known_headers.include?(header.strip.downcase)
          bad_header = true
          log.error("In document #{file} the #{header} is an unsupported header")
          master_log.error("#{@failure}#{file} contains unsupported header(s)")
        end
      end
      
      if not bad_header
        changes.each do |row|
          #Get the Solr Document and set it for updating 
          
        
          #DEBUG AREA
          save_id = row[sourceid] if local_testing
          row[sourceid] = debug_source_id if local_testing
        
          #Attempt to get the target based on the source_id
          #target = Blacklight.solr.select(:params =>{:q=>'source_id_ssi:"'+ row['sourceid']+'"'})["response"]["docs"][0]
          target = find_doc_via_blacklight(row[@sourceid])
          
      
          
          #If we can't get the target based on source_id, try it with the filename
          if(target == nil and row[filename] != nil)
            alt_attempt = row[filename]
            alt_attempt.slice! file_ext
            target = find_doc_via_blacklight(alt_attempt)
            #target = Blacklight.solr.select(:params =>{:q=>'source_id_ssi:"'+ alt_attempt+'"'})["response"]["docs"][0]
          end
          
       
          #Catch sourceid with no matching druid
          if target == nil
            log.error("In document #{file} no druid found for #{row[sourceid]}") 
            error_count += 1
          end 
          
          if target != nil #Begin Altering Single Solr Document
             doc = SolrDocument.new(target)
           
             #If we have comma splits, replace them with the expected seperator 
             comma_splits.each do |key|
               row[key] = row[key].strip.gsub(comma, seperator) if row[key] != nil
             end
           
           
             #Check to see if we have a format row and clean it up
             
             #Assume there is no change to the format field and we should ignore this key
             ignore_fields.insert(0, format) if not ignore_fields.include?(format)
             
             if row[format] != nil
               current_format = target[SolrDocument.field_mappings[:formats][:field]]
               current_format = current_format.sort if current_format != nil
               format_changes = cleanFormat(row[format].strip.downcase.split(seperator)).sort
               
               #We have changes 
               if current_format != format_changes
                  row[format] = format_changes.join(seperator)
                  ignore_fields.delete(format) #Pull it out of the ignore fields since we need to make changes here. 
                else
               end
               
             end

           
             #Check to see if we have a location and see if we need to parse it.
             row = parseLocation(row, location) if row[location] != nil
           
             #Check to see if we need need to handle marques
             if row[marque] != nil 
               array_marque = row[marque].split(seperator)
               count = 0 
               array_marque.each do |m|
                 result = revs_lookup_marque(m, marque_file)
                 array_marque[count] = result['value'] if result
                 count += 1
               end
               row[marque] = array_marque.join(seperator)
               #puts row[marque]
             end 
           
             #We could have a full date, a year, or a span of years, handle that.
             if row[year] != nil
               is_full_date = SolrDocument.get_full_date(row[year])
               if is_full_date
                 row[full_date] = row[year]
                 row[year] = nil if year != full_date
               else
                 row[csv_to_solr[year] || year ] = SolrDocument.parse_years(row[year]).join(seperator)
                 row[year] = nil if(csv_to_solr[year] != nil and csv_to_solr[year] != year) #Clear whatever the csv used for year/date if it is not the proper Solr key
               end
             end
             
             #Handle multiple model_years
             if row[model_year] != nil
               row[model_year] = SolrDocument.parse_years(row[model_year]).join(seperator)
             end
           
           
             (changes.headers()+additional_fields-ignore_fields).each do |key|
               key = key.strip.downcase
               #First make sure we have a real change
               if row[key] != nil
                 #See if the solr document calls the key something else
                   if csv_to_solr[key] != nil
                     proper_key_name = csv_to_solr[key.strip]
                   else
                     proper_key_name = key
                   end   
           
                   #Set up multivalue and send it the value 
                   args = assigner 
                   args = multi+assigner if multi_values.include?(proper_key_name) 
               
                   begin 
                        doc.send(proper_key_name+args, row[key].strip)
                        #puts "Sending: #{proper_key_name+args} #{row[key].strip}" 
                   rescue
                       log.error("In document #{file} on row #{row[sourceid]}, failed to send the key: #{proper_key_name+args} and value: #{row[key]}")
                   end 
               end
             end
           
             success = doc.save
           
             log.error("In document #{file} save error for #{save_id} "+" #{changes.headers()-ignore_fields+additional_fields} #{row}") if(not success and local_testing)
             log.error("In document #{file} save error for #{row[sourceid]}") if(not success and not local_testing)
             error_count  += 1 if not success 
           
           end #End Altering Single Solr Document   
          
        end
        master_log.info("#{@success}#{file} had no errors.") if error_count == 0
        master_log.error("#{@failure}#{file} had #{error_count} error(s).") if error_count != 0
        puts file if local_testing
        puts error_count if local_testing
      end
      
    
    end 
  end
  
  def parseLocation(row, location)
    row[location].split('|').reverse.each do |local|
      country = revs_get_country(local)
      city_state = revs_get_city_state(local) 
      row['country'] = country.strip if country 
      if city_state
        row['state'] = revs_get_state_name(city_state[1].strip)
        row['city'] = city_state[0].strip
      end
      if not city_state and not country
        row['city_section'] = local
      end
    end
    
    return row
  end 
  
    def revs_get_country(name)
      name='US' if name=='USA' # special case; USA is not recognized by the country gem, but US is
      country=Country.find_country_by_name(name.strip) # find it by name
      code=Country.new(name.strip) # find it by code
      if country.nil? && code.data.nil? 
        return false
      else
        return (code.data.nil? ? country.name : code.name)
      end
    end # revs_get_country
  
    # parse a string like this: "San Mateo (Calif.)" to try and figure out if there is any state in there; if found, return the city and state as an array, if none found, return false
    def revs_get_city_state(name)
      state_match=name.match(/[(]\S+[)]/)
      if state_match.nil?
        return false
      else
        first_match=state_match[0]
        state=first_match.gsub(/[()]/,'').strip # remove parens and strip
        city=name.gsub(first_match,'').strip # remove state name from input string and strip
        return [city,state]
      end
    end # revs_get_city_state
  
    # given an abbreviated state name (e.g. "Calif." or "CA") return the full state name (e.g. "California")
    def revs_get_state_name(name)
      test_name=name.gsub('.','').strip.downcase
      us=Country.new('US')
      us.states.each do |key,value|
        if value['name'].downcase.start_with?(test_name) || key.downcase == test_name
          return value['name']
          break
        end
      end
      return name
    end # revs_get_state_name
  
    
    
  def cleanFormat(format)
    known_fixes = {"black-and-white negative"=>"black-and-white negatives",
                   "color negative"=>"color negatives",
                   "slides/color transparency"=>"color transparencies",
                   "color negatives/slides"=>"color negatives",
                   "black-and-white negative strips"=>"black-and-white negatives",
                   "color transparency"=>"color transparencies",
                   "slide"=>"slides"
                 }
    count = 0 
    format.each do |f|
      format[count] = known_fixes[f] || f
      count += 1
    end
    
    return format
  end
  
  def revs_lookup_marque(marque, a_lc_t)
    result=false
    variants1=[marque,marque.capitalize,marque.singularize,marque.pluralize,marque.capitalize.singularize,marque.capitalize.pluralize]
    variants2=[]
    variants1.each do |name| 
      variants2 << "#{name} automobile" 
      variants2 << "#{name} automobiles"
    end
    (variants1+variants2).each do |variant|
      lookup_term=a_lc_t[variant]
      if lookup_term
        result={'url'=>lookup_term,'value'=>variant}
        break
      end
    end
    
    return result
  end 
  
  def load_csv_files_from_directory(file_location)
    return Dir.glob(File.join(file_location, @csv_extension_wild))
  end
  
  def read_csv_with_headers(file)
     return CSV.parse(File.read(file), :headers => true )
  end
  
  def find_doc_via_blacklight(source)
     return Blacklight.solr.select(:params =>{:q=>'source_id_ssi:"'+ source+'"'})["response"]["docs"][0]
  end
  
end
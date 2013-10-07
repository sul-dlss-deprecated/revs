require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'
require 'csv'
require 'countries'
require 'date'

namespace :revs do
  desc "Load all changes to the metadata from CSV files located in TBD"
  task :bulk_load => :environment do
    local_testing = true
    debug_source_id = '2012-027NADI-1967-b1_1.0_0008'
    log = Logger.new(STDOUT)
    log.level = Logger::ERROR
    marque_file = File.open('/tmp/revs-lc-marque-terms.obj','rb'){|io| Marshal.load(io)}
    change_file_location = "/tmp/debug"
    change_file_extension = "*.csv"
    sourceid = 'sourceid'
    location = "location"
    format = "format"
    marque = "marque"
    filename = "filename"
    year = "year"
    full_date = "full_date"
    seperator = "|"
    assigner = "="
    mutli = "_mvf"
    ignore_fields = [sourceid, location, marque, filename]  
    #special_fields = ['year', 'marque', 'model', 'people', 'location']
    location_fields = ['country', 'city', 'state']
    additional_fields = location_fields + [full_date]#add other arrays here if we do anymore splitting
    multivalue_fields = []
  
    #Map the csv names to the field names from 
    csv_to_solr = {'label' => 'title',   
                   'model'  => 'vehicle_model',
                   year => 'years',
                   format => 'formats',
                   'collection_name' => 'collection_names'
                  }
   
   #These should be the field name from /app/,odels/solr_document.rb
   multi_values = ['vehicle_model', 'years', "formats", "model_years", "marque", "people"]
  
    
   #Get a list of all the files we need to process and loop over them
   change_files = Dir.glob(File.join(change_file_location, change_file_extension))
    
    #Process Each File 
    change_files.each do |file| 
      
      #Load in the CSV, with the top row being taken as the header
      changes = CSV.parse(File.read(file), :headers => true )
      changes.each do |row|
        #Get the Solr Document and set it for updating 
        
        
        #DEBUG AREA
        save_id = row[sourceid] if local_testing
        row[sourceid] = debug_source_id if local_testing
        
        
        target = Blacklight.solr.select(:params =>{:q=>'source_id_ssi:"'+ row['sourceid']+'"'})["response"]["docs"][0]
       
       
        #Catch sourceid with no matching druid
        log.error("In document #{file} no druid found for #{row[sourceid]}") if target == nil
        
        if target != nil #Begin Altering Single Solr Document
           doc = SolrDocument.new(target)
           
           #Check to see if we have a format row and clean it up
           row[format] = cleanFormat(row[format].strip.split(seperator)).join(seperator) if row[format] != nil
          
           
           #Check to see if we have a location and see if we need to parse it.
           row = parseLocation(row, location) if row[location] != nil
           
           #Check to see if we need need to handle marques
           if row[marque] != nil 
             array_marque = row[marque].split(seperator)
             count = 0 
             array_marque.each do |m|
               array_marque[count] = revs_lookup_marque(m, marque_file)
               count += 1
             end
             row[marque] = array_marque.join(seperator)
             #puts row[marque]
           end 
           
           #Check to see if we have a full date or just a year for the photograph date
           #TODO:  This could handle things much better
           #Note:  The Date gem assumes the form dd/mm/yyyy but REVS is using the format mm/dd/yyyy, so use caution when using the Date gem 
           if row[year] != nil and row[year].strip.size > 4
               row[full_date] = row[year]
               row[year] = nil
           end
           
           
           (changes.headers()-ignore_fields+additional_fields).each do |key|
             
             #First make sure we have a real change
             if row[key] != nil
               #See if the solr document calls the key something else
                 if csv_to_solr[key] != nil
                   proper_key_name = csv_to_solr[key]
                 else
                   proper_key_name = key
                 end   
           
                 #Set up multivalue and send it the value 
                 args = assigner 
                 args = mutli+assigner if multi_values.include?(proper_key_name) 
               
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
           log.error("In document #{file} save error for #{row[sourceod]}") if(not success and not local_testing)
            
           
         end #End Altering Single Solr Document
        
        #doc.send('title=',"aaaaaaaffhhhhhh"})
        
        
        
        #puts doc.save
        
        
        
        
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
  end # revs_lookup_marque
end
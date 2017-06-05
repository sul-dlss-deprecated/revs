# encoding: UTF-8

require 'jettywrapper' unless (Rails.env.production? || Rails.env.staging?)
require 'rest_client'
require 'csv'
require 'countries'
require 'pathname'
require 'revs-utils'
require 'nokogiri'
$stdout.sync = true

namespace :revs do
  desc "Export all metadata for a given collection to CSV - used to facilitate transfer of revs content to contentDM"
  # https://www.oclc.org/support/services/contentdm/help/project-client-help/entering-metadata/using-tab-delimited-text-files.en.html
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_csv collection="John Dugdale Collection" # must be limited to a collection
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_csv collection="John Dugdale Collection" limit=100 # optionally sets a limit of number of items
  #Run Me: RAILS_ENV=production nohup bundle exec rake revs:export_metadata_to_csv collection="John Dugdale Collection" > export.log 2>&1& # nohup mode with logged output

  task :export_metadata_to_csv  => :environment do |t, args|

    limit = ENV['limit'] || '' # if passed, limits to this many items only
    collection = ENV['collection'] || '' # if passed, limits to this collection only
    raise "you must provide a collection" if collection.blank?
    
    q="*:*"
    q+=" AND collection_ssim:\"#{collection}\"" 

    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :fl=>'id', :rows=>rows})
    total_docs=@all_docs['response']['docs'].size

    start_time=Time.now
    n=0
    num_errors=0
    output_file = "log/#{collection.gsub(" ","_")}_#{Time.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')}.txt"

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}" 
    puts " limited to #{limit} items" unless limit.blank?
    puts " found #{total_docs} items"

    puts ""
    puts q
    puts ""

    CSV.open(output_file, "wb", {:col_sep => "\t"}) do |csv|

      revs_field_mappings = SolrDocument.new.revs_field_mappings.with_indifferent_access
      excluded_fields = ['resaved_at','identifier','single_year','archive_name','collections','highlighted'] # exclude these

      header_row = []
      revs_field_mappings.each { |field, config| header_row << field.to_s unless excluded_fields.include? field.to_s } # write out all fields to the header
      csv << ['druid','identifier'] + header_row + ['filename'] # add extra columns we need

      @all_docs['response']['docs'].each do |doc|

        id=doc['id']
        n+=1
        puts "#{n} of #{total_docs}: #{id}"
         begin
           s=SolrDocument.find(id)
           data_row = []
           data_row += [s.id,s.identifier] # add druid and source id
           header_row.each do |column|  # go throught the rest of the columns
             value = s[revs_field_mappings[column][:field]]
             if revs_field_mappings[column][:multi_valued] == true && !value.blank?
               data_row << value.map {|val| val.to_s.gsub('"',"'")}.join(";")
             elsif column == 'full_date' # format full date to contentDM standard, assuming it is a standard format
               data_row << (s.revs_is_valid_datestring?(s.full_date) && !s.full_date.blank? ? Chronic.parse(s.full_date).to_date.strftime('%m/%d/%Y') : nil)
             else 
               data_row << (value.blank? ? nil : value.to_s.gsub('"',"'")) # replace double quotes with single quotes, as suggested by contenDM import  
             end
           end
           data_row += ["#{s['image_id_ssm'].first}.tif"] # add filename (it is a multi_valued field, but revs image always only have a single image)
           csv << data_row
         rescue => e
           puts " *** ERROR #{e.message}: #{id}"
           num_errors+=1
         end
      end

    end
    
    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} exported, #{num_errors} errors"
    puts " output to #{output_file}"
    puts ""

  end
end
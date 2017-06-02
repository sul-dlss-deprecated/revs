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
  desc "Export all metadata for a given collection to CSV - used to facilitate transfer of revs content"
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

      csv << SolrDocument.new.revs_field_mappings.map { |field, config| field.to_s } # write out all fields to the header
      
      @all_docs['response']['docs'].each do |doc|

        id=doc['id']
        n+=1
        puts "#{n} of #{total_docs}: #{id}"
         begin
           s=SolrDocument.find(id)
           data_row = []
           s.revs_field_mappings.each do |field, config| 
             if config[:multi_valued] == true && !s[config[:field]].blank?
               data_row << s[config[:field]].join(";")
             else
               data_row << s[config[:field]] 
             end
           end
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
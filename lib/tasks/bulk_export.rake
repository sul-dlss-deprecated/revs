# encoding: UTF-8

require 'rest_client'
require 'countries'
require 'pathname'
require 'revs-utils'
require 'nokogiri'
$stdout.sync = true

def cleanup_export_value(input_value,delimiter,delimiter_replace)
    return nil if input_value.blank?
    value = input_value.to_s
    value.gsub! /\t/, '  ' # remove tabs
    value.gsub! /\n/, '  ' # remove CRs
    value.gsub! /\r/, '  ' # remove linefeeds
    value.gsub! delimiter.strip, delimiter_replace # convert delimiter to a different character in the values to prevent problems
    value.blank? ? nil : value.to_s
end

namespace :revs do
  desc "Export all metadata for a given collection to TXT - used to facilitate transfer of revs content to contentDM"
  # https://www.oclc.org/support/services/contentdm/help/project-client-help/entering-metadata/using-tab-delimited-text-files.en.html
  # You *must* provide a collection.
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_txt collection="John Dugdale Collection" # must be limited to a collection
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_txt collection="John Dugdale Collection" limit=100 # optionally sets a limit of number of items (defaults to no limit)
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_txt collection="John Dugdale Collection" max_rows=1000 # optionally sets maximum number of rows per spreadsheet (autosplit based on this number, defaults to 1000)
  #Run Me: RAILS_ENV=production bundle exec rake revs:export_metadata_to_txt collection="John Dugdale Collection" visibility="visible" # only visible images are exported (defaults to "visible", can also pass "all" or "hidden")
  #Run Me: RAILS_ENV=production nohup bundle exec rake revs:export_metadata_to_txt collection="John Dugdale Collection" > export.log 2>&1& # nohup mode with logged output

  task :export_metadata_to_txt  => :environment do |t, args|

    include ActionView::Helpers::NumberHelper # for nice display output and time computations in output
    collection = ENV['collection'] || '' # limits to this collection only
    limit = ENV['limit'] || '' # if passed, limits to this many items only (default is no limit)
    max_rows = ENV['max_rows'] || 1000 # if passed, limits to this many items only (default is 1000)
    visibility = ENV['visibility'] || "visible" # can be passed as "all", "visible" (default) or "hidden".  Filters images by their visibility
    additional_query = ENV['additional_query'] || nil # an additional solr query you can pass it to further restrict the results

    raise "you must provide a collection" if collection.blank?

    q="*:*"
    q+=" AND collection_ssim:\"#{collection}\""
    case visibility
       when "visible"
         q+= " AND -visibility_isi:#{SolrDocument.visibility_mappings[:hidden]}"
       when "hidden"
         q+= " AND visibility_isi:#{SolrDocument.visibility_mappings[:hidden]}"
     end
    q+=" AND #{additional_query}" if additional_query

    rows = limit.blank? ? "1000000" : limit

    @all_docs = Blacklight.default_index.connection.select(:params => {:q => q, :fl=>'id', :rows=>rows, :sort=>'source_id_ssi ASC'})
    total_docs=@all_docs['response']['docs'].size

    start_time=Time.now
    n=1
    file_number=0
    num_errors=0
    output_each=200
    delimiter = "; " # delimiter for multivalued fields
    delimiter_replace = "," # when the delimiter exists in actual values, it will replaced with this character
    max_rows = max_rows.to_i # maximum number of rows in any given spreadsheet
    excluded_fields = ['car_group','car_class','group_class','timestamp','priority','resaved_at','identifier','single_year','archive_name','collections','highlighted','subjects'] # exclude these fields in output
    files = []
    output_file = nil

    base_output_filename = "log/#{collection.gsub(" ","_")}_#{visibility}_#{Time.now.strftime('%Y-%m-%dT%H-%M-%S')}" # base name for output file(s)

    puts ""
    puts "Started at #{start_time}, #{total_docs} docs returned"
    puts " limited to collection: #{collection}"
    puts " limited to #{limit} items" unless limit.blank?
    puts " found #{total_docs} items"
    puts " maximum rows per file: #{max_rows}"
    puts " visibility: #{visibility}"
    puts " base output file to #{base_output_filename}"
    puts ""
    puts "query: #{q}"
    puts ""

    number_of_files = (total_docs.to_f / max_rows).ceil

    revs_field_mappings = SolrDocument.new.revs_field_mappings.with_indifferent_access
    header_columns = []
    revs_field_mappings.each { |field, config| header_columns << field.to_s unless excluded_fields.include? field.to_s } # write out all fields to the header that are not excluded

    @all_docs['response']['docs'].each do |doc|

      if n % max_rows == 1 # the start of a new file
        file_number += 1
        output_filename = "#{base_output_filename}_#{file_number}.txt"
        files << output_filename
        output_file.close unless output_file.nil?
        output_file = File.open(output_filename, 'wb:UTF-8')
        puts "Writing file #{file_number} of #{number_of_files}: #{output_filename}"
        header_row = ['druid','identifier']
        header_row += header_columns + ['group_class','filename','filename_repeat']  # add extra columns we need
        output_file.write header_row.join("\t")+"\n"
      end

      id=doc['id']
      n+=1
      if n % output_each == 0 # provide some feedback every X docs
        puts "...#{Time.now}: on document #{number_with_delimiter(n)} of #{number_with_delimiter(total_docs)}"
      end
      begin
         s=SolrDocument.find(id)
         data_row = []
         data_row += [s.id,s.identifier] # add druid and source id
         header_columns.each do |column|  # go through the rest of the columns
           value = s.send(column)
           if column == 'full_date' # format full date to contentDM standard, assuming it is a standard format
             data_row << (s.get_full_date(s.full_date) ? Chronic.parse(s.full_date).to_date.strftime('%Y-%m-%d') : "")
           elsif revs_field_mappings[column][:multi_valued] == true && value.class == Array # multi_valued field
             data_row << value.map {|val| cleanup_export_value(val,delimiter,delimiter_replace)}.join(delimiter)
           else # any other non-multivalued or special field
             data_row << cleanup_export_value(value,delimiter,delimiter_replace)
           end
         end
         data_row += [[s.group_class,s.car_group,s.car_class].flatten.reject(&:blank?).join(', ')] # recombined separate group and class fields and combine with group_class field and make single valued again
         filename = "#{s['image_id_ssm'].first}.tif" # the filename is a multi_valued field, but revs image always only have a single image so grab the first
         data_row += [filename,filename] # add filename twice
         output_file.write data_row.join("\t")+"\n"
      rescue => e
         puts " *** ERROR #{e.message}: #{id}"
         num_errors+=1
      end
    end

    end_time=Time.now

    puts ""
    puts "Finished at #{Time.now}, total files: #{number_of_files}, run lasted #{((end_time-start_time)/60).round} minutes, #{total_docs} exported, #{num_errors} errors"
    puts ""
    puts "#{number_of_files} files created: "
    files.each {|file| puts file}
  end
end
